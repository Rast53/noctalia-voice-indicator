from __future__ import annotations

import json
import os
from pathlib import Path
import re
import stat
from .config import DEFAULT_ENV_PATH, VoiceTypeConfig, load_env_file
from .state import set_state

DEFAULT_ENV_TEXT = """# Noctalia Voice Type local configuration
# This file is private. Do not commit it.

VOICE_TYPE_PROVIDER=deepgram
VOICE_TYPE_LANGUAGE={language}
VOICE_TYPE_STATE_FILE=/tmp/voice-type-state.json
VOICE_TYPE_INSERT_METHOD=wayland-clipboard

# F11 long dictation auto-stop: finish after this many seconds of silence.
# Set to 0 to disable auto-stop.
VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS=10
VOICE_TYPE_AUTO_STOP_MIN_RECORD_SECONDS=2
VOICE_TYPE_AUTO_STOP_RMS_THRESHOLD=500

# Deepgram
DEEPGRAM_API_KEY=
DEEPGRAM_MODEL=nova-3

# Planned / experimental OpenAI-compatible provider
OPENAI_COMPAT_BASE_URL=
OPENAI_COMPAT_API_KEY=
OPENAI_COMPAT_MODEL=
"""


def default_language() -> str:
    lang = os.environ.get("LANG", "") or os.environ.get("LC_ALL", "")
    return "ru" if lang.lower().startswith("ru") else "en"


def ensure_env_file(path: Path = DEFAULT_ENV_PATH, language: str | None = None) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        try:
            path.chmod(stat.S_IRUSR | stat.S_IWUSR)
        except Exception:
            pass
        return False
    lang = language if language not in {None, "auto"} else default_language()
    path.write_text(DEFAULT_ENV_TEXT.format(language=lang), encoding="utf-8")
    path.chmod(stat.S_IRUSR | stat.S_IWUSR)
    return True


def ensure_state_file(config: VoiceTypeConfig | None = None) -> None:
    config = config or VoiceTypeConfig.from_env()
    set_state(config.state_file, "ready")


def _quote_env(value: str) -> str:
    if value == "":
        return ""
    if re.search(r"[\s#'\"]", value):
        return '"' + value.replace('"', '\\"') + '"'
    return value


def update_env_values(values: dict[str, str], path: Path = DEFAULT_ENV_PATH) -> None:
    ensure_env_file(path)
    existing = path.read_text(encoding="utf-8").splitlines()
    seen: set[str] = set()
    out: list[str] = []
    for line in existing:
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            out.append(line)
            continue
        key = stripped.split("=", 1)[0].strip()
        if key in values:
            out.append(f"{key}={_quote_env(values[key])}")
            seen.add(key)
        else:
            out.append(line)
    for key, value in values.items():
        if key not in seen:
            out.append(f"{key}={_quote_env(value)}")
    path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    path.chmod(stat.S_IRUSR | stat.S_IWUSR)


def find_noctalia_plugin_settings() -> list[Path]:
    base = Path.home() / ".config" / "noctalia" / "plugins"
    if not base.exists():
        return []
    candidates = []
    for path in base.glob("*/settings.json"):
        try:
            text = path.read_text(encoding="utf-8")
            if "deepgram" in text and ("transcription" in text or "apiKeys" in text):
                candidates.append(path)
        except Exception:
            continue
    return sorted(candidates, key=lambda p: p.stat().st_mtime, reverse=True)


def load_plugin_transcription(path: Path | None = None) -> tuple[Path, dict[str, str]]:
    candidates = [path] if path else find_noctalia_plugin_settings()
    if not candidates or candidates[0] is None:
        raise RuntimeError("No Noctalia Voice Type plugin settings.json found.")
    src = candidates[0]
    data = json.loads(src.read_text(encoding="utf-8"))
    transcription = data.get("transcription", data)
    api_keys = transcription.get("apiKeys", {}) if isinstance(transcription, dict) else {}
    values = {
        "VOICE_TYPE_PROVIDER": str(transcription.get("provider", "deepgram")),
        "VOICE_TYPE_LANGUAGE": str(transcription.get("language", default_language())),
        "DEEPGRAM_MODEL": str(transcription.get("model", "nova-3")),
    }
    deepgram_key = api_keys.get("deepgram") if isinstance(api_keys, dict) else ""
    if deepgram_key:
        values["DEEPGRAM_API_KEY"] = str(deepgram_key)
    return src, values


def sync_noctalia_settings(path: Path | None = None) -> Path:
    src, values = load_plugin_transcription(path)
    update_env_values(values)
    load_env_file(DEFAULT_ENV_PATH)
    ensure_state_file()
    return src


def init_config(language: str | None = None) -> bool:
    created = ensure_env_file(language=language)
    ensure_state_file()
    return created
