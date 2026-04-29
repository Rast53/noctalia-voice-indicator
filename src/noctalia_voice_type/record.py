from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path


def record_wav_until_enter() -> bytes:
    """Small portable dev helper: record with arecord until Enter is pressed."""
    with tempfile.NamedTemporaryFile(prefix="voice_type_", suffix=".wav", delete=False) as tmp:
        path = Path(tmp.name)
    proc = subprocess.Popen(
        ["arecord", "-f", "S16_LE", "-r", "16000", "-c", "1", "-t", "wav", str(path)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        input("Recording... press Enter to stop. ")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
    data = path.read_bytes()
    path.unlink(missing_ok=True)
    return data
