from __future__ import annotations

import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

from .config import VoiceTypeConfig
from .insert import insert_text
from .providers import build_provider
from .record import start_arecord
from .silence import is_tail_silent
from .state import set_state

RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir())) / "noctalia-voice-type"


def _session_path(kind: str) -> Path:
    return RUNTIME_DIR / f"{kind}.json"


def _read_session(kind: str) -> dict[str, object] | None:
    path = _session_path(kind)
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def _write_session(kind: str, data: dict[str, object]) -> None:
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    _session_path(kind).write_text(json.dumps(data), encoding="utf-8")


def _update_session(kind: str, updates: dict[str, object]) -> None:
    data = _read_session(kind) or {}
    data.update(updates)
    _write_session(kind, data)


def _clear_session(kind: str) -> None:
    _session_path(kind).unlink(missing_ok=True)


def _is_pid_running(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _start_auto_stop_watcher(kind: str) -> int:
    proc = subprocess.Popen(
        [sys.executable, "-m", "noctalia_voice_type.cli", "watch-silence", kind],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    return int(proc.pid)


def watch_silence(kind: str, config: VoiceTypeConfig | None = None) -> int:
    config = config or VoiceTypeConfig.from_env()
    if config.auto_stop_silence_seconds <= 0:
        return 0

    silent_since: float | None = None
    while True:
        session = _read_session(kind)
        if not session:
            return 0
        pid = int(session.get("pid", -1))
        if pid <= 0 or not _is_pid_running(pid):
            return 0
        wav_path = Path(str(session.get("wav_path", "")))
        started_at = float(session.get("started_at", time.time()))
        now = time.time()
        if now - started_at < config.auto_stop_min_record_seconds:
            silent_since = None
            time.sleep(0.5)
            continue

        silent = is_tail_silent(wav_path, config.auto_stop_rms_threshold, tail_seconds=1.0)
        if silent is None:
            silent_since = None
        elif silent:
            if silent_since is None:
                silent_since = now
            elapsed_silence = now - silent_since
            remaining = max(0, int(config.auto_stop_silence_seconds - elapsed_silence + 0.999))
            if remaining > 0:
                set_state(
                    config.state_file,
                    "recording",
                    str(remaining),
                    autoStop=True,
                    countdown=remaining,
                    silenceSeconds=config.auto_stop_silence_seconds,
                )
            if elapsed_silence >= config.auto_stop_silence_seconds:
                return _stop(kind, config, stopped_by="auto_silence")
        else:
            if silent_since is not None:
                set_state(config.state_file, "recording")
            silent_since = None
        time.sleep(0.5)


def _start(kind: str, config: VoiceTypeConfig) -> int:
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    existing = _read_session(kind)
    if existing and _is_pid_running(int(existing.get("pid", -1))):
        print(f"{kind} recording is already running; stopping it instead.")
        return _stop(kind, config)

    with tempfile.NamedTemporaryFile(prefix=f"noctalia_voice_{kind}_", suffix=".wav", delete=False) as tmp:
        wav_path = Path(tmp.name)
    proc = start_arecord(wav_path)
    session = {"pid": proc.pid, "wav_path": str(wav_path), "started_at": time.time()}
    _write_session(kind, session)
    set_state(config.state_file, "recording")
    if kind == "stream" and config.auto_stop_silence_seconds > 0:
        watcher_pid = _start_auto_stop_watcher(kind)
        _update_session(kind, {"watcher_pid": watcher_pid})
    print(f"{kind} recording started")
    return 0


def _stop(kind: str, config: VoiceTypeConfig, stopped_by: str = "manual") -> int:
    session = _read_session(kind)
    if not session:
        set_state(config.state_file, "ready")
        print(f"{kind} recording is not running")
        return 0

    pid = int(session.get("pid", -1))
    wav_path = Path(str(session.get("wav_path", "")))
    try:
        if pid > 0 and _is_pid_running(pid):
            os.kill(pid, signal.SIGINT)
            deadline = time.time() + 2.0
            while time.time() < deadline and _is_pid_running(pid):
                time.sleep(0.05)
            if _is_pid_running(pid):
                os.kill(pid, signal.SIGTERM)
        watcher_pid = int(session.get("watcher_pid", -1) or -1)
        if watcher_pid > 0 and watcher_pid != os.getpid() and _is_pid_running(watcher_pid):
            try:
                os.kill(watcher_pid, signal.SIGTERM)
            except OSError:
                pass
        _clear_session(kind)
        if not wav_path.exists() or wav_path.stat().st_size < 128:
            set_state(config.state_file, "error", "empty recording")
            raise RuntimeError("Recording file is empty or missing")

        set_state(config.state_file, "processing")
        wav_bytes = wav_path.read_bytes()
        wav_path.unlink(missing_ok=True)
        text = build_provider(config).transcribe_wav(wav_bytes).strip()
        if text:
            set_state(config.state_file, "success")
            insert_text(text, config.insert_method)
            if stopped_by == "auto_silence":
                print("auto-stopped after silence")
            print(text)
        else:
            set_state(config.state_file, "ready")
            print("No speech recognized")
        return 0
    except Exception as exc:
        set_state(config.state_file, "error", str(exc))
        raise
    finally:
        # Give the indicator a small success/error flash window, then hide back to idle.
        time.sleep(0.6)
        set_state(config.state_file, "ready")


def toggle(kind: str, config: VoiceTypeConfig | None = None) -> int:
    if kind not in {"batch", "stream"}:
        raise RuntimeError(f"Unsupported toggle kind: {kind}")
    config = config or VoiceTypeConfig.from_env()
    session = _read_session(kind)
    if session and _is_pid_running(int(session.get("pid", -1))):
        return _stop(kind, config)
    _clear_session(kind)
    return _start(kind, config)
