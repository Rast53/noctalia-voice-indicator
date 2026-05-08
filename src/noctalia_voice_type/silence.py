from __future__ import annotations

from pathlib import Path
import struct


WAV_HEADER_BYTES = 44
DEFAULT_SAMPLE_RATE = 16_000
DEFAULT_SAMPLE_WIDTH = 2
DEFAULT_CHANNELS = 1


def pcm16_rms(data: bytes) -> int:
    """Return RMS for signed 16-bit little-endian PCM bytes."""
    if len(data) < 2:
        return 0
    if len(data) % 2:
        data = data[:-1]
    count = len(data) // 2
    samples = struct.unpack(f"<{count}h", data)
    if not samples:
        return 0
    return int((sum(sample * sample for sample in samples) / len(samples)) ** 0.5)


def wav_tail_rms(
    path: Path,
    tail_seconds: float = 1.0,
    sample_rate: int = DEFAULT_SAMPLE_RATE,
    sample_width: int = DEFAULT_SAMPLE_WIDTH,
    channels: int = DEFAULT_CHANNELS,
) -> int | None:
    """Return RMS for the last `tail_seconds` of an arecord WAV file.

    We intentionally read the PCM tail directly instead of trusting the WAV
    header while recording. Some recorders only finalize header sizes on close,
    but the raw PCM payload is already appended after the 44-byte header.
    """
    try:
        data = path.read_bytes()
    except Exception:
        return None
    if len(data) <= WAV_HEADER_BYTES + sample_width:
        return None
    payload = data[WAV_HEADER_BYTES:]
    bytes_per_second = sample_rate * sample_width * channels
    tail_bytes = max(sample_width, int(bytes_per_second * max(0.1, tail_seconds)))
    tail = payload[-tail_bytes:]
    # Current recorder is mono S16_LE. If this becomes stereo later, this still
    # gives a conservative energy estimate over all interleaved samples.
    return pcm16_rms(tail)


def is_tail_silent(path: Path, rms_threshold: int, tail_seconds: float = 1.0) -> bool | None:
    rms = wav_tail_rms(path, tail_seconds=tail_seconds)
    if rms is None:
        return None
    return rms < rms_threshold
