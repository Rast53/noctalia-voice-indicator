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
cli="$HOME/.local/bin/noctalia-voice-type"
if command -v noctalia-voice-type >/dev/null 2>&1; then
  cli="noctalia-voice-type"
elif [ -x "$cli" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if command -v noctalia-voice-type >/dev/null 2>&1; then
  noctalia-voice-type init-config || true
  echo
  noctalia-voice-type doctor --human || true
  echo
  echo "Niri snippet:"
  noctalia-voice-type niri-snippet || true
else
  echo "WARN: noctalia-voice-type is not on PATH yet. Open a new shell or ensure ~/.local/bin is in PATH." >&2
fi

echo
cat <<MSG
Next steps:
  1. Add your Deepgram key:
     - edit ~/.config/noctalia-voice-type/env, or
     - enter it in Noctalia plugin settings and run: noctalia-voice-type sync-noctalia-settings
  2. Run: noctalia-voice-type doctor --human
  3. Add the niri snippet above to ~/.config/niri/config.kdl.
  4. Reload niri: niri msg action load-config
  5. Restart Noctalia if the bar widget is not visible.

Повторный запуск безопасен: репозиторий обновится, env-файл и ключи сохранятся.
MSG
