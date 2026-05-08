# Fresh CachyOS setup

Install the Noctalia plugin from the Plugin Manager first, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash
```

The script is safe to re-run. It installs dependencies, clones/updates the repository under `~/.local/src/noctalia-voice-type`, installs the Python CLI, creates `~/.config/noctalia-voice-type/env` if missing, creates the state file, runs `doctor --human`, and prints the niri keybind snippet.

## Add Deepgram key

Option A:

```bash
$EDITOR ~/.config/noctalia-voice-type/env
```

Option B: enter the key in the Noctalia plugin settings, save, then run:

```bash
noctalia-voice-type sync-noctalia-settings
```

## Add niri binds

```bash
noctalia-voice-type niri-snippet
```

Paste output into `~/.config/niri/config.kdl`, then reload:

```bash
niri msg action load-config
```

Suggested defaults:

- F12 — short/batch dictation toggle.
- F11 — long dictation toggle.

## Verify

```bash
noctalia-voice-type doctor --human
```

See also:

- English full guide: [en-install.md](en-install.md)
- Русская инструкция: [ru-install.md](ru-install.md)
