# Progress

## Status: SUCCESS

### Completed steps
- [x] Captured context and plan.
- [x] Added env config for F11 silence auto-stop.
- [x] Added raw PCM tail RMS detector that works while `arecord` is still writing the WAV.
- [x] Added detached `watch-silence` helper for `toggle-stream` only.
- [x] Preserved manual second-F11 stop behavior.
- [x] Updated README/config/niri/install docs.

### Verification
- `python3 -m compileall -q src`
- Generated WAV fixture tests: silent tail below threshold, loud tail above threshold.
- Simulated unfinalized arecord-style WAV header + PCM payload.
- `doctor --human` includes auto-stop config.
- `git diff --check`

### Notes
- F12 remains manual toggle.
- F11 auto-stop default: 10 seconds of silence after 2 seconds minimum recording.
- Disable with `VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS=0`.
