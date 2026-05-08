# Plan

1. Add silence-related config values to `VoiceTypeConfig` and `.env.example`.
2. Add small WAV silence detector using stdlib RMS calculation.
3. Start a detached watcher process for `toggle-stream` sessions only.
4. Watcher stops/transcribes via existing `_stop` path after `VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS` seconds of silence.
5. Update docs and doctor output.
6. Verify with generated WAV fixtures and compile checks.
