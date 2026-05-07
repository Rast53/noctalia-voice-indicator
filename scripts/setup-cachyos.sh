#!/usr/bin/env bash
set -euo pipefail

repo_url="${NOCTALIA_VOICE_TYPE_REPO:-https://github.com/Rast53/noctalia-voice-indicator}"
repo_dir="${NOCTALIA_VOICE_TYPE_REPO_DIR:-$HOME/.local/src/noctalia-voice-type}"

if command -v pacman >/dev/null 2>&1; then
  echo "Installing system dependencies with pacman..."
  sudo pacman -S --needed git python python-pip python-virtualenv alsa-utils wl-clipboard wtype
else
  echo "WARN: pacman not found. Install these manually: git python python-pip python-virtualenv alsa-utils wl-clipboard wtype" >&2
fi

mkdir -p "$(dirname "$repo_dir")"
if [ -d "$repo_dir/.git" ]; then
  echo "Updating existing repo at $repo_dir"
  git -C "$repo_dir" pull --ff-only
else
  echo "Cloning $repo_url to $repo_dir"
  git clone "$repo_url" "$repo_dir"
fi

"$repo_dir/scripts/install-cli.sh"

echo
if command -v noctalia-voice-type >/dev/null 2>&1; then
  noctalia-voice-type doctor || true
  echo
  echo "Niri snippet:"
  noctalia-voice-type niri-snippet || true
else
  echo "WARN: noctalia-voice-type is not on PATH yet. Open a new shell or ensure ~/.local/bin is in PATH." >&2
fi

echo
cat <<MSG
Next steps:
  1. Edit ~/.config/noctalia-voice-type/env and set DEEPGRAM_API_KEY.
  2. Add the niri snippet above to ~/.config/niri/config.kdl.
  3. Reload niri: niri msg action load-config
  4. Restart Noctalia if the bar widget is not visible.
MSG
