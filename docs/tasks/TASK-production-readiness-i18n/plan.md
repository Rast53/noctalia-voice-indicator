# Plan

1. Add locale-aware EN/RU text helpers to plugin settings and bar tooltip.
2. Add CLI support for syncing Noctalia plugin STT settings into the CLI env without exposing secrets.
3. Improve `doctor` with actionable OK/WARN/ERROR checks and exit code.
4. Make install scripts production-ish: create state file, preserve env, optional Noctalia settings sync, clear next steps.
5. Add bilingual installation documentation and update README.
6. Run syntax/compile checks and update project memory.

## Rollback
Use git to revert this task's commits/files. No destructive migrations or external services are touched.
