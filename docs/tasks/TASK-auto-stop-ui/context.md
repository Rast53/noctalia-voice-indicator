# TASK: Auto-stop pause setting in plugin UI

## Goal
Let users choose F11 auto-stop pause duration from the Noctalia plugin settings.

## Scope
- Default: 10 seconds.
- Reasonable range: 3–30 seconds.
- Allow disabling auto-stop via toggle.
- Persist in plugin settings and sync to CLI env.

## Constraints
- CLI env remains the actual runtime source for the CLI.
- User must run `noctalia-voice-type sync-noctalia-settings` after changing plugin settings, unless future automation is added.
- Secrets must not be printed.
