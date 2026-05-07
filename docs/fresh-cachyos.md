# Fresh CachyOS setup

Install the Noctalia plugin from the Plugin Manager first, then run the local voice typing setup:

```bash
curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash
```

The script installs system dependencies, clones/updates this repository under `~/.local/src/noctalia-voice-type`, installs the Python CLI, creates `~/.config/noctalia-voice-type/env`, runs `doctor`, and prints the niri keybind snippet.

Then edit:

```bash
$EDITOR ~/.config/noctalia-voice-type/env
```

Set:

```env
DEEPGRAM_API_KEY=...
```

Add the output of:

```bash
noctalia-voice-type niri-snippet
```

to `~/.config/niri/config.kdl`, then reload niri:

```bash
niri msg action load-config
```

Suggested defaults:

- F12 — short/batch dictation toggle.
- F11 — long dictation toggle.

The plugin settings page also contains this checklist and a local setup status/doctor view.
