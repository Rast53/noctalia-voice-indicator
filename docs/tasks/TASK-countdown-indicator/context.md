# TASK: Countdown indicator during F11 silence pause

## Goal
When F11 long dictation detects silence, show an auto-stop countdown in the Noctalia bar indicator: 5, 4, 3, 2, 1, then stop.

## Scope
- Writer: `watch_silence` updates `/tmp/voice-type-state.json` while silent.
- Reader: `BarWidget.qml` overlays countdown text on orb/wave.
- Countdown uses configured `VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS`.

## Constraints
- Do not affect F12.
- Clear countdown immediately when speech resumes.
- Keep state-file backwards compatible: `state`, `message`, `ts` still exist.
