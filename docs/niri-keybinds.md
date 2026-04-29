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
