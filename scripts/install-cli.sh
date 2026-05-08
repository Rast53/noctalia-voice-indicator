#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
venv_dir="${NOCTALIA_VOICE_TYPE_VENV:-$HOME/.local/share/noctalia-voice-type/venv}"
bin_dir="$HOME/.local/bin"
config_dir="$HOME/.config/noctalia-voice-type"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1" >&2; exit 1; }; }
need git

if command -v python >/dev/null 2>&1; then
  python_cmd=python
elif command -v python3 >/dev/null 2>&1; then
  python_cmd=python3
else
  echo "ERROR: missing command: python or python3" >&2
  exit 1
fi

mkdir -p "$bin_dir" "$config_dir"
if "$python_cmd" -m venv "$venv_dir" 2>/tmp/noctalia-voice-type-venv.err; then
  "$venv_dir/bin/python" -m pip install -U pip
  "$venv_dir/bin/python" -m pip install -e "$repo_dir"
  ln -sf "$venv_dir/bin/noctalia-voice-type" "$bin_dir/noctalia-voice-type"
else
  cat /tmp/noctalia-voice-type-venv.err >&2 || true
  echo "$python_cmd -m venv failed; falling back to per-user pip install." >&2
  if ! "$python_cmd" -m pip --version >/dev/null 2>&1; then
    echo "ERROR: pip is not available for $python_cmd." >&2
    echo "FIX: install python-pip (Arch/CachyOS: sudo pacman -S --needed python-pip) or run scripts/setup-cachyos.sh." >&2
    exit 1
  fi
  "$python_cmd" -m pip install --user -e "$repo_dir"
fi

if command -v "$bin_dir/noctalia-voice-type" >/dev/null 2>&1; then
  "$bin_dir/noctalia-voice-type" init-config || true
else
  echo "WARN: CLI symlink was not created; cannot initialize config automatically." >&2
fi

if [ -f "$config_dir/env" ]; then
  chmod 600 "$config_dir/env"
  echo "Config file ready: $config_dir/env"
fi

cat <<MSG
Installed noctalia-voice-type CLI.

Next:
  1. Put your Deepgram key into $config_dir/env, or enter it in the plugin settings and run:
     noctalia-voice-type sync-noctalia-settings
  2. Check readiness:
     noctalia-voice-type doctor --human
  3. Add niri binds from:
     noctalia-voice-type niri-snippet
MSG
