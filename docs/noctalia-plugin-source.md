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

Noctalia clones only the `voice-type-indicator/` subdirectory from this repository. That directory contains:

- `manifest.json`
- `BarWidget.qml`
- `Settings.qml`

The Python voice typing CLI is intentionally kept at the repository root and must be installed separately for real dictation.

## Fresh CachyOS voice typing setup

After installing the plugin from Noctalia, open the plugin settings for the setup checklist, or install the local CLI with:

```bash
curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash
```

Manual path:

```bash
git clone https://github.com/Rast53/noctalia-voice-indicator ~/.local/src/noctalia-voice-type
cd ~/.local/src/noctalia-voice-type
python -m venv ~/.local/share/noctalia-voice-type/venv
~/.local/share/noctalia-voice-type/venv/bin/python -m pip install -U pip
~/.local/share/noctalia-voice-type/venv/bin/python -m pip install -e .
mkdir -p ~/.local/bin ~/.config/noctalia-voice-type
ln -sf ~/.local/share/noctalia-voice-type/venv/bin/noctalia-voice-type ~/.local/bin/noctalia-voice-type
cp .env.example ~/.config/noctalia-voice-type/env
chmod 600 ~/.config/noctalia-voice-type/env
$EDITOR ~/.config/noctalia-voice-type/env
```

Required system packages on CachyOS/Arch:

```bash
sudo pacman -S --needed git python python-pip python-virtualenv alsa-utils wl-clipboard wtype
```

Then check:

```bash
noctalia-voice-type doctor
noctalia-voice-type niri-snippet
```

Add the generated binds to `~/.config/niri/config.kdl`, restart niri/Noctalia, and use the configured keys.
