# Install from Noctalia Plugin Manager

This repository is a Noctalia plugin source.

## Add source

1. Open **Noctalia Settings → Plugins → Sources**.
2. Click **Add plugin source**.
3. Fill:
   - Repository Name: `Noctalia Voice Type`
   - Repository URL: `https://github.com/Rast53/noctalia-voice-indicator`
4. Refresh available plugins.
5. Install **Voice Type Indicator**.
6. Enable it and add `plugin:voice-type-indicator` to the bar if Noctalia does not add it automatically.

## What the plugin manager installs

Noctalia installs the `voice-type-indicator/` subdirectory from this repository:

- `manifest.json`
- `BarWidget.qml`
- `Settings.qml`

The Python voice typing CLI lives at the repository root and must be installed separately for real dictation.

## Production install flow

Use the bilingual guides:

- English: [en-install.md](en-install.md)
- Русский: [ru-install.md](ru-install.md)

Short version for CachyOS/Arch:

```bash
curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash
noctalia-voice-type doctor --human
noctalia-voice-type niri-snippet
```

Add a Deepgram key either in `~/.config/noctalia-voice-type/env` or in the plugin settings followed by:

```bash
noctalia-voice-type sync-noctalia-settings
```
