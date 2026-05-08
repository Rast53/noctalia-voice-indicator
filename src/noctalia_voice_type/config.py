from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path


DEFAULT_ENV_PATH = Path.home() / ".config" / "noctalia-voice-type" / "env"


def load_env_file(path: Path = DEFAULT_ENV_PATH) -> None:
    """Load KEY=VALUE lines without overriding already exported environment variables."""
    if not path.exists():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


@dataclass(frozen=True)
class VoiceTypeConfig:
    provider: str
    language: str
    state_file: str
    insert_method: str
    deepgram_api_key: str
    deepgram_model: str
    openai_compat_base_url: str
    openai_compat_api_key: str
    openai_compat_model: str
    auto_stop_silence_seconds: float
    auto_stop_min_record_seconds: float
    auto_stop_rms_threshold: int

    @classmethod
    def from_env(cls) -> "VoiceTypeConfig":
        load_env_file()
        return cls(
            provider=os.environ.get("VOICE_TYPE_PROVIDER", "deepgram").strip().lower(),
            language=os.environ.get("VOICE_TYPE_LANGUAGE", "ru").strip(),
            state_file=os.environ.get("VOICE_TYPE_STATE_FILE", "/tmp/voice-type-state.json").strip(),
            insert_method=os.environ.get("VOICE_TYPE_INSERT_METHOD", "wayland-clipboard").strip(),
            deepgram_api_key=(
                os.environ.get("DEEPGRAM_API_KEY")
                or os.environ.get("NOCTALIA_VOICE_TYPE_DEEPGRAM_API_KEY")
                or ""
            ).strip(),
            deepgram_model=os.environ.get("DEEPGRAM_MODEL", "nova-3").strip(),
            openai_compat_base_url=os.environ.get("OPENAI_COMPAT_BASE_URL", "").strip(),
            openai_compat_api_key=os.environ.get("OPENAI_COMPAT_API_KEY", "").strip(),
            openai_compat_model=os.environ.get("OPENAI_COMPAT_MODEL", "").strip(),
            auto_stop_silence_seconds=float(os.environ.get("VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS", "10") or "10"),
            auto_stop_min_record_seconds=float(os.environ.get("VOICE_TYPE_AUTO_STOP_MIN_RECORD_SECONDS", "2") or "2"),
            auto_stop_rms_threshold=int(os.environ.get("VOICE_TYPE_AUTO_STOP_RMS_THRESHOLD", "500") or "500"),
        )
