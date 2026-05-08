# Plan

1. Extend `set_state` to accept extra JSON fields.
2. In `watch_silence`, compute remaining seconds and write `message=countdown`, `countdown=<n>`, `autoStop=true` while silence is active.
3. Clear message/countdown when speech resumes.
4. In BarWidget, parse message/countdown and overlay large countdown text only during recording.
5. Bump plugin version and docs.
6. Verify with compile/QML checks and state JSON fixtures.
