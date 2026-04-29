# State file contract

`Noctalia Voice Indicator` is intentionally dumb: it does not record audio and does not call any transcription API.

It only visualizes the current voice-input state from a JSON file.

Default path:

```text
/tmp/voice-type-state.json
```

Schema:

```json
{
  "state": "recording",
  "message": "optional text",
  "ts": 1777460000
}
```

## States

| State | Meaning |
| --- | --- |
| `idle` | idle state |
| `hidden` | treated as idle |
| `ready` | treated as idle |
| `recording` | microphone is recording/listening |
| `processing` | transcription is being processed |
| `success` | transcription completed |
| `error` | something failed |

## Writers

Any script can update the file. Example:

```bash
python3 - <<'PY'
import json, time
json.dump({"state":"recording","message":"","ts":time.time()}, open('/tmp/voice-type-state.json','w'))
PY
```
