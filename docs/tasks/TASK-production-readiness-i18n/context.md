# TASK: Production readiness + i18n

## Goal
Turn Noctalia Voice Type from a locally hand-tuned spike into an installable user-facing flow.

## Source of truth
- Plugin source: `voice-type-indicator/`
- Root QML mirrors: `BarWidget.qml`, `Settings.qml`, `manifest.json`
- CLI: `src/noctalia_voice_type/`
- Install scripts: `scripts/setup-cachyos.sh`, `scripts/install-cli.sh`
- Docs: `README.md`, `docs/`

## Current pain points
- User can install the Noctalia plugin, but real dictation requires manual CLI/env/niri work.
- Plugin settings can store Deepgram key, but CLI reads `~/.config/noctalia-voice-type/env`; these can drift.
- UI strings are mixed English/Russian and not locale-aware.
- Doctor output is too raw for end users.

## Constraints
- Never print or commit API keys.
- Keep Deepgram as the only stable provider.
- Keep niri F12=batch and F11=long defaults configurable.
- Installer must be idempotent and safe to re-run.
