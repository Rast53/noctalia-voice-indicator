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


def recordings_dir() -> Path:
    """Каталог WAV-записей: внутри RUNTIME_DIR пользователя, а не общий /tmp.

    /tmp на части хостов — tmpfs (RAM); забытая запись там съедает память
    и роняет сборки, которым нужен /tmp.
    """
    return RUNTIME_DIR / "recordings"


def cleanup_stale_recordings(config: VoiceTypeConfig | None = None) -> tuple[int, int]:
    """Удаляет осиротевшие WAV старше `stale_record_hours`.

    Сирота — файл в каталоге записей, на который не ссылается ни одна активная
    сессия (batch/stream). Возвращает (файлов убрано, байт освобождено).
    """
    config = config or VoiceTypeConfig.from_env()
    directory = recordings_dir()
    if not directory.is_dir():
        return (0, 0)
    active: set[str] = set()
    for kind in ("batch", "stream"):
        session = _read_session(kind)
        if session and session.get("wav_path"):
            active.add(str(session["wav_path"]))
    cutoff = time.time() - max(0.0, config.stale_record_hours) * 3600.0
    removed = 0
    freed = 0
    for path in directory.glob("noctalia_voice_*.wav"):
        try:
            if str(path) in active:
                continue
            stat = path.stat()
            if stat.st_mtime > cutoff:
                continue
            path.unlink()
            removed += 1
            freed += stat.st_size
        except OSError:
            continue
    return (removed, freed)


def recordings_stats() -> tuple[int, int]:
    """Сколько WAV лежит в каталоге записей и сколько они занимают байт."""
    count = 0
    total = 0
    directory = recordings_dir()
    if directory.is_dir():
        for path in directory.glob("noctalia_voice_*.wav"):
            try:
                count += 1
                total += path.stat().st_size
            except OSError:
                continue
    return (count, total)


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


def _start_limit_watcher(kind: str) -> int:
    proc = subprocess.Popen(
        [sys.executable, "-m", "noctalia_voice_type.cli", "watch-limit", kind],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    return int(proc.pid)


def watch_limit(kind: str, config: VoiceTypeConfig | None = None) -> int:
    """Закрывает запись, когда arecord завершился сам по `--duration`.

    Без этого сторожа состояние остаётся `recording`, а файл на диске никто
    не обрабатывает (пользователь думает, что запись идёт).
    """
    config = config or VoiceTypeConfig.from_env()
    while True:
        session = _read_session(kind)
        if not session:
            return 0
        pid = int(session.get("pid", -1))
        if pid <= 0:
            return 0
        if not _is_pid_running(pid):
            if not _read_session(kind):
                return 0
            return _stop(kind, config, stopped_by="auto_limit")
        time.sleep(0.5)


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

    directory = recordings_dir()
    directory.mkdir(parents=True, exist_ok=True)
    removed, freed = cleanup_stale_recordings(config)
    if removed:
        print(f"cleaned {removed} stale recording(s), freed {freed / (1024 * 1024):.1f} MiB")

    with tempfile.NamedTemporaryFile(
        prefix=f"noctalia_voice_{kind}_", suffix=".wav", dir=directory, delete=False
    ) as tmp:
        wav_path = Path(tmp.name)
    proc = start_arecord(wav_path, config.max_record_seconds)
    session = {"pid": proc.pid, "wav_path": str(wav_path), "started_at": time.time()}
    _write_session(kind, session)
    set_state(config.state_file, "recording")
    if kind == "stream" and config.auto_stop_silence_seconds > 0:
        watcher_pid = _start_auto_stop_watcher(kind)
        _update_session(kind, {"watcher_pid": watcher_pid})
    elif config.max_record_seconds > 0:
        # arecord завершится сам по --duration; сторож закроет сессию и отправит
        # запись на распознавание, иначе состояние висит в "recording".
        watcher_pid = _start_limit_watcher(kind)
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
            elif stopped_by == "auto_limit":
                print("stopped at recording limit")
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
