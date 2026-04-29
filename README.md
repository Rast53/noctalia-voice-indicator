# Noctalia Voice Indicator

A tiny, configurable voice-dictation status indicator for the [Noctalia](https://github.com/noctalia-dev/noctalia-shell) shell / Quickshell ecosystem.

It was built for a niri + Wayland desktop where floating GTK overlays were unreliable: instead of trying to place a separate window on the screen, the indicator lives directly in the top Noctalia bar.

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
- Designed for F11/F12 voice dictation flows, but usable with any script that writes the same state file.

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
