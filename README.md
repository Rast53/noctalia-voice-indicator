# Noctalia Voice Type

A Wayland/niri voice typing toolkit with a configurable [Noctalia](https://github.com/noctalia-dev/noctalia-shell) / Quickshell bar indicator.

It started as a fix for unreliable floating GTK overlays on niri: instead of placing a separate window on screen, the status indicator lives directly in the top Noctalia bar. The product direction is broader: local hotkeys + provider-based transcription + safe text insertion + shell UI feedback.


## Product direction

This project is not just a microphone indicator. The intended shape is:

```text
niri hotkey → record audio → transcribe via provider → insert text → update Noctalia indicator
```

Provider goals:

- **Deepgram** — first-class provider, user supplies `DEEPGRAM_API_KEY`.
- **OpenRouter / OpenAI-compatible** — planned/experimental provider where users can set base URL, API key, and a model capable of audio transcription.
- Local/private config only; no API keys in git.

See [Configuration](docs/configuration.md).

## Features

- Bar widget for Noctalia / Quickshell.
- Reads voice input state from `/tmp/voice-type-state.json`.
- Multiple visual styles:
  - **Siri orb** — small animated glowing orb.
  - **Color wave** — animated gaussian-like color bars.
- Configurable from Noctalia settings:
  - visual style;
  - idle dot size;
  - active capsule width;
  - idle opacity;
  - recording / processing / success / error / idle colors;
  - idle visibility;
  - pulse animation.
- Designed for compositor-native niri keybinds. F11/F12 are suggested defaults, not hardcoded requirements.

## Preview

_Currently text-only; screenshots/GIFs are planned._

States:

```json
{"state":"recording","message":"","ts":1777460000}
{"state":"processing","message":"","ts":1777460001}
{"state":"success","message":"","ts":1777460002}
{"state":"error","message":"","ts":1777460003}
{"state":"hidden","message":"","ts":1777460004}
```


## CLI prototype

The repository now includes an early Python CLI prototype:

```bash
python -m pip install -e .
cp .env.example ~/.config/noctalia-voice-type/env
chmod 600 ~/.config/noctalia-voice-type/env
$EDITOR ~/.config/noctalia-voice-type/env

noctalia-voice-type doctor
noctalia-voice-type transcribe-file sample.wav
noctalia-voice-type record-once --insert
```

The current stable provider is Deepgram. OpenRouter/OpenAI-compatible transcription is tracked as roadmap work because gateway audio support differs by model/provider.

## Installation

Clone or copy this plugin into your Noctalia plugins directory:

```bash
git clone https://github.com/Rast53/noctalia-voice-indicator.git \
  ~/.config/noctalia/plugins/voice-type-indicator
```

Enable it in `~/.config/noctalia/plugins.json`:

```json
{
  "states": {
    "voice-type-indicator": {
      "enabled": true,
      "sourceUrl": "local"
    }
  }
}
```

Add it to the bar in `~/.config/noctalia/settings.json`, for example in the right section:

```json
{
  "id": "plugin:voice-type-indicator"
}
```

Restart Noctalia / Quickshell:

```bash
pkill -f "qs -c noctalia-shell"
QT_QPA_PLATFORM=wayland qs -c noctalia-shell
```

Exact restart details depend on your compositor/session manager.


## Keybinds

On Wayland, global hotkeys should be owned by the compositor. For niri, use native binds and point them at the CLI commands. F11/F12 are only defaults; users can choose any niri-compatible key spec.

Generate a snippet:

```bash
noctalia-voice-type niri-snippet
noctalia-voice-type niri-snippet --batch-key "Mod+V" --stream-key "Mod+Shift+V"
```

See [Niri keybinds](docs/niri-keybinds.md).

## State file contract

The widget watches:

```text
/tmp/voice-type-state.json
```

Expected format:

```json
{
  "state": "recording",
  "message": "optional text",
  "ts": 1777460000
}
```

Supported states:

- `idle` / `hidden` / `ready` — idle state;
- `recording` — actively listening;
- `processing` — transcription is being processed;
- `success` — transcription completed;
- `error` — something failed.

Minimal shell example:

```bash
python3 - <<'PY'
import json, time
json.dump({"state":"recording","message":"","ts":time.time()}, open('/tmp/voice-type-state.json','w'))
PY
```

## Development

This repository contains a local Noctalia plugin:

```text
manifest.json
BarWidget.qml
Settings.qml
```

There is no build step. Edit QML files, copy/symlink them into `~/.config/noctalia/plugins/voice-type-indicator`, and restart Noctalia.

## Roadmap

See [GitHub issues](https://github.com/Rast53/noctalia-voice-indicator/issues).

Planned ideas:

- screenshots / animated GIF previews;
- installer script;
- better color picker integration if Noctalia exposes a stable one;
- more visual styles;
- configurable state file path;
- packaging for easier plugin distribution.

## License

MIT — see [LICENSE](LICENSE).
