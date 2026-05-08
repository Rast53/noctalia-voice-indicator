# Noctalia Voice Type

A Wayland/niri voice typing toolkit with a configurable [Noctalia](https://github.com/noctalia-dev/noctalia-shell) / Quickshell bar indicator.

It is meant to be installed by regular users, not hand-wired per machine:

```text
niri hotkey → record audio → transcribe via Deepgram → insert text → update Noctalia indicator
```

## Languages / Языки

- English install guide: [docs/en-install.md](docs/en-install.md)
- Русская инструкция: [docs/ru-install.md](docs/ru-install.md)

The plugin UI is locale-aware: `ru*` system locale uses Russian, every other locale uses English. F11 auto-stop pause is configurable in plugin settings: default 10 seconds, range 3–30 seconds.

## Quick install

### 1. Add the Noctalia plugin source

Open **Noctalia Settings → Plugins → Sources** and add:

- Repository Name: `Noctalia Voice Type`
- Repository URL: `https://github.com/Rast53/noctalia-voice-indicator`

Install and enable **Voice Type Indicator**.

### 2. Install the local CLI on CachyOS/Arch

```bash
curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash
```

The script is idempotent: it updates the repo, preserves your private env file, creates the state file, installs the CLI, and prints a niri snippet.

### 3. Add your Deepgram key

Either edit:

```bash
$EDITOR ~/.config/noctalia-voice-type/env
```

or enter the key in the plugin settings, save, then run:

```bash
noctalia-voice-type sync-noctalia-settings
```

### 4. Add niri binds

```bash
noctalia-voice-type niri-snippet
```

Paste into `~/.config/niri/config.kdl`, then reload niri:

```bash
niri msg action load-config
```

Defaults:

- `F12` — short/batch dictation toggle.
- `F11` — long dictation: press once to start; it auto-stops after the configured silence pause, or press F11 again to stop manually. Default pause: 10 seconds.

### 5. Check readiness

```bash
noctalia-voice-type doctor --human
```

## Features

- Noctalia/Quickshell bar widget.
- Visual states: idle, recording, processing, success, error.
- Two indicator styles:
  - **Siri orb** — glowing animated orb.
  - **Color wave** — animated gaussian-like color bars.
- Locale-aware plugin settings UI: Russian for `ru*`, English otherwise.
- Idempotent CachyOS/Arch installer.
- Private local config in `~/.config/noctalia-voice-type/env`.
- Secret-safe diagnostics with `noctalia-voice-type doctor`.
- Deepgram STT provider (`nova-3` by default).
- F11 silence countdown overlay: when a pause is detected, the bar shows `5 4 3 2 1` before auto-stop.
- Compositor-native niri keybind snippet generation.

## CLI

```bash
noctalia-voice-type init-config
noctalia-voice-type doctor --human
noctalia-voice-type sync-noctalia-settings
noctalia-voice-type transcribe-file sample.wav
noctalia-voice-type record-once --insert
noctalia-voice-type toggle-batch
noctalia-voice-type toggle-stream
noctalia-voice-type niri-snippet
```

## Configuration

Private config lives at:

```text
~/.config/noctalia-voice-type/env
```

Minimal Deepgram config:

```env
VOICE_TYPE_PROVIDER=deepgram
VOICE_TYPE_LANGUAGE=ru
VOICE_TYPE_STATE_FILE=/tmp/voice-type-state.json
VOICE_TYPE_INSERT_METHOD=wayland-clipboard
VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS=10
DEEPGRAM_API_KEY=your-key
DEEPGRAM_MODEL=nova-3
```

See [docs/configuration.md](docs/configuration.md).

## State file contract

The widget watches:

```text
/tmp/voice-type-state.json
```

Expected format:

```json
{"state":"recording","message":"optional text","ts":1777460000}
```

Supported states:

- `idle` / `hidden` / `ready`
- `recording`
- `processing`
- `success`
- `error`

## Development

This repository is a Noctalia plugin source:

```text
registry.json
voice-type-indicator/manifest.json
voice-type-indicator/BarWidget.qml
voice-type-indicator/Settings.qml
```

Root-level `manifest.json`, `BarWidget.qml`, and `Settings.qml` are development mirrors.

Install locally for development:

```bash
python -m venv ~/.local/share/noctalia-voice-type/venv
~/.local/share/noctalia-voice-type/venv/bin/python -m pip install -e .
ln -sf ~/.local/share/noctalia-voice-type/venv/bin/noctalia-voice-type ~/.local/bin/noctalia-voice-type
```

## Roadmap

- OpenAI-compatible/OpenRouter transcription provider after audio API behavior is proven stable.
- Screenshot/GIF previews.
- More desktop environments after niri flow is solid.
