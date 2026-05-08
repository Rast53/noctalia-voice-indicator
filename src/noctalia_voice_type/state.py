from __future__ import annotations

import json
from pathlib import Path
import time


def set_state(path: str, state: str, message: str = "", **extra: object) -> None:
    try:
        payload = {"state": state, "message": message, "ts": time.time()}
        payload.update(extra)
        Path(path).write_text(
            json.dumps(payload),
            encoding="utf-8",
        )
    except Exception:
        # Indicator state must never break dictation.
        pass
