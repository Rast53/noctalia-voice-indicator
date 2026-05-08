# Install Noctalia Voice Type

Goal: install the Noctalia plugin, run one CLI setup command, add a Deepgram key and niri keybinds, then use F12/F11 voice typing without manual patching.

## 1. Install the Noctalia plugin

1. Open **Noctalia Settings → Plugins → Sources**.
2. Click **Add plugin source**.
3. Use:
   - Repository Name: `Noctalia Voice Type`
   - Repository URL: `https://github.com/Rast53/noctalia-voice-indicator`
4. Refresh plugins.
5. Install and enable **Voice Type Indicator**.
6. If Noctalia does not add it automatically, add `plugin:voice-type-indicator` to the bar.

## 2. Install the local CLI

On CachyOS/Arch:

```bash
curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash
```

The script is safe to re-run. It:

- installs system dependencies with `pacman`;
- clones/updates the repo in `~/.local/src/noctalia-voice-type`;
- installs the Python CLI into a venv;
- creates `~/.config/noctalia-voice-type/env` if missing;
- creates the indicator state file;
- prints diagnostics and a niri snippet.

## 3. Add a Deepgram key

Option A — env file:

```bash
$EDITOR ~/.config/noctalia-voice-type/env
```

Fill:

```env
DEEPGRAM_API_KEY=your-key
VOICE_TYPE_LANGUAGE=en
```

Option B — Noctalia plugin settings:

1. Enter the key in **Deepgram API key**.
2. Save settings.
3. Run:

```bash
noctalia-voice-type sync-noctalia-settings
```

The command copies provider/model/language/key into the private CLI env file and never prints the key.

## 4. Add niri keybinds

```bash
noctalia-voice-type niri-snippet
```

Paste the output into `~/.config/niri/config.kdl`, then run:

```bash
niri msg action load-config
```

Defaults:

- `F12` — short dictation: press → speak → press again → text is inserted.
- `F11` — long dictation: press once to start; it auto-stops after 10 seconds of silence, or press F11 again to stop manually.

## 5. Check readiness

```bash
noctalia-voice-type doctor --human
```

Required checks should be `OK`. Secrets are never printed.

## Localization

The plugin UI chooses language automatically:

- system locale `ru*` → Russian;
- every other locale → English.

The default STT language follows the locale when the env file is created for the first time: `ru` on Russian systems, `en` otherwise.
