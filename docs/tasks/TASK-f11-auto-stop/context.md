# TASK: F11 auto-stop on silence

## Goal
Improve long dictation UX: user presses F11 once, speaks, and recording stops automatically after a configurable silence pause.

## Scope
- Stable target: F11 / `toggle-stream` only.
- F12 / `toggle-batch` keeps manual toggle semantics.
- Use local recording audio, no new service dependency.

## Constraints
- Must still allow second F11 press to stop manually.
- Default silence timeout: 10 seconds.
- Avoid printing secrets.
- Must be configurable through env.
