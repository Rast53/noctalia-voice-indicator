from __future__ import annotations

import signal
import subprocess
import tempfile
from pathlib import Path


def _read_wav(path: Path) -> bytes:
    data = path.read_bytes()
    path.unlink(missing_ok=True)
    return data


def start_arecord(path: Path) -> subprocess.Popen[bytes]:
    return subprocess.Popen(
        ["arecord", "-f", "S16_LE", "-r", "16000", "-c", "1", "-t", "wav", str(path)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def stop_arecord(proc: subprocess.Popen[bytes]) -> None:
    if proc.poll() is not None:
        return
    proc.send_signal(signal.SIGINT)
    try:
        proc.wait(timeout=2)
    except subprocess.TimeoutExpired:
        proc.terminate()
        try:
            proc.wait(timeout=1)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()


def record_wav_until_enter() -> bytes:
    """Small portable dev helper: record with arecord until Enter is pressed."""
    with tempfile.NamedTemporaryFile(prefix="voice_type_", suffix=".wav", delete=False) as tmp:
        path = Path(tmp.name)
    proc = start_arecord(path)
    try:
        input("Recording... press Enter to stop. ")
    finally:
        stop_arecord(proc)
    return _read_wav(path)
