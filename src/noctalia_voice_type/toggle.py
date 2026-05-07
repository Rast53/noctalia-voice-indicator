from __future__ import annotations

import json
import os
from pathlib import Path
import signal
import tempfile
import time

from .config import VoiceTypeConfig
from .insert import insert_text
from .providers import build_provider
from .record import start_arecord
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


def _clear_session(kind: str) -> None:
    _session_path(kind).unlink(missing_ok=True)


def _is_pid_running(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _start(kind: str, config: VoiceTypeConfig) -> int:
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    existing = _read_session(kind)
    if existing and _is_pid_running(int(existing.get("pid", -1))):
        print(f"{kind} recording is already running; stopping it instead.")
        return _stop(kind, config)

    with tempfile.NamedTemporaryFile(prefix=f"noctalia_voice_{kind}_", suffix=".wav", delete=False) as tmp:
        wav_path = Path(tmp.name)
    proc = start_arecord(wav_path)
    _write_session(kind, {"pid": proc.pid, "wav_path": str(wav_path), "started_at": time.time()})
    set_state(config.state_file, "recording")
    print(f"{kind} recording started")
    return 0


def _stop(kind: str, config: VoiceTypeConfig) -> int:
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
