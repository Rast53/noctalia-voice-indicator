from __future__ import annotations

import subprocess
import time


def insert_text(text: str, method: str = "wayland-clipboard") -> None:
    if method == "none":
        print(text)
        return
    if method == "wayland-clipboard":
        subprocess.run(["wl-copy"], input=text.encode("utf-8"), check=False)
        time.sleep(0.03)
        subprocess.run(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"], check=False)
        return
    if method == "x11-clipboard":
        subprocess.run(["xclip", "-selection", "clipboard"], input=text.encode("utf-8"), check=False)
        subprocess.run(["xdotool", "key", "--clearmodifiers", "Shift+Insert"], check=False)
        return
    raise RuntimeError(f"Unsupported insert method: {method}")
