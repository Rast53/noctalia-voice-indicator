from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path

from .config import DEFAULT_ENV_PATH, VoiceTypeConfig


@dataclass(frozen=True)
class Check:
    key: str
    status: str
    message: str
    fix: str = ""


def _path_exists(path: str) -> bool:
    try:
        return Path(path).expanduser().exists()
    except Exception:
        return False


def run_checks(config: VoiceTypeConfig | None = None) -> list[Check]:
    config = config or VoiceTypeConfig.from_env()
    checks: list[Check] = []

    cli = shutil.which("noctalia-voice-type")
    checks.append(
        Check(
            "cli_executable",
            "OK" if cli else "ERROR",
            cli or "noctalia-voice-type is not on PATH",
            "Run scripts/setup-cachyos.sh, then open a new shell or add ~/.local/bin to PATH.",
        )
    )

    checks.append(
        Check(
            "env_file",
            "OK" if DEFAULT_ENV_PATH.exists() else "WARN",
            str(DEFAULT_ENV_PATH) if DEFAULT_ENV_PATH.exists() else f"{DEFAULT_ENV_PATH} is missing",
            "Run noctalia-voice-type init-config or scripts/install-cli.sh.",
        )
    )

    for cmd, package in [("arecord", "alsa-utils"), ("wl-copy", "wl-clipboard"), ("wtype", "wtype")]:
        found = shutil.which(cmd)
        checks.append(
            Check(
                f"command_{cmd}",
                "OK" if found else "ERROR",
                found or f"{cmd} is missing",
                f"Install package: {package}.",
            )
        )

    checks.append(
        Check(
            "provider",
            "OK" if config.provider == "deepgram" else "ERROR",
            config.provider,
            "Set VOICE_TYPE_PROVIDER=deepgram. Other providers are not stable yet.",
        )
    )

    checks.append(
        Check(
            "deepgram_api_key",
            "OK" if bool(config.deepgram_api_key) else "ERROR",
            "set" if config.deepgram_api_key else "not set",
            "Add DEEPGRAM_API_KEY to ~/.config/noctalia-voice-type/env or run sync-noctalia-settings after saving plugin settings.",
        )
    )

    checks.append(Check("deepgram_model", "OK", config.deepgram_model or "nova-3"))
    checks.append(Check("language", "OK", config.language or "auto"))
    checks.append(Check("state_file", "OK" if _path_exists(config.state_file) else "WARN", config.state_file, "It will be created automatically; run init-config to create it now."))
    checks.append(Check("insert_method", "OK", config.insert_method))
    return checks


def has_errors(checks: list[Check]) -> bool:
    return any(c.status == "ERROR" for c in checks)


def format_checks(checks: list[Check], human: bool = False) -> str:
    if not human:
        return "\n".join(f"{c.key}={c.status} {c.message}" for c in checks)

    icons = {"OK": "OK", "WARN": "WARN", "ERROR": "ERROR"}
    lines = ["Noctalia Voice Type doctor"]
    for c in checks:
        line = f"[{icons.get(c.status, c.status)}] {c.key}: {c.message}"
        if c.status != "OK" and c.fix:
            line += f"\n  fix: {c.fix}"
        lines.append(line)
    lines.append("Result: " + ("needs attention" if has_errors(checks) else "ready"))
    return "\n".join(lines)
