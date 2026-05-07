# Niri keybinds

Noctalia Voice Type should not own global hotkeys itself on Wayland.

On niri, the recommended design is:

```text
niri bind → noctalia-voice-type command → state JSON → Noctalia indicator
```

This keeps hotkeys compositor-native and avoids brittle X11/pynput-style global listeners.

## Default bindings

Suggested defaults:

- `F12` — short batch dictation toggle.
- `F11` — long/streaming dictation toggle.

But these are only defaults. Users can choose any niri-compatible key combination.

## Generate config snippet

```bash
noctalia-voice-type niri-snippet
```

Custom keys:

```bash
noctalia-voice-type niri-snippet \
  --batch-key "Mod+V" \
  --stream-key "Mod+Shift+V"
```

Append the output to:

```text
~/.config/niri/config.kdl
```

Then reload niri config:

```bash
niri msg action load-config
```

## Toggle behavior

The commands are toggles:

- first key press starts recording and sets the Noctalia state to `recording`;
- second key press stops recording, transcribes, inserts text through `wl-copy` + `wtype Ctrl+V`, then returns the indicator to idle.

`toggle-stream` currently preserves the long-dictation/F11 user interface but uses the same robust batch transcription path internally. Provider-level streaming is future work.

## Manual snippet

```kdl
binds {
    F12 allow-when-locked=false repeat=false {
        spawn "noctalia-voice-type" "toggle-batch";
    }

    F11 allow-when-locked=false repeat=false {
        spawn "noctalia-voice-type" "toggle-stream";
    }
}
```

For custom keys, replace `F12` / `F11` with any niri key spec, for example:

```kdl
binds {
    Mod+V repeat=false {
        spawn "noctalia-voice-type" "toggle-batch";
    }

    Mod+Shift+V repeat=false {
        spawn "noctalia-voice-type" "toggle-stream";
    }
}
```

## Why not configure keys inside the plugin?

The Noctalia plugin is UI only. It should render state, not capture global keyboard events.

Keeping keybinds in niri has three advantages:

1. Works correctly on Wayland.
2. Shows up in niri/keybind cheat sheets.
3. Lets each user pick keys using their compositor's normal config.
