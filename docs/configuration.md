# Configuration

Noctalia Voice Type never ships with private API keys. Users provide credentials locally.

Private config path:

```text
~/.config/noctalia-voice-type/env
```

Create it with:

```bash
noctalia-voice-type init-config
```

or through the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash
```

## Deepgram provider

Deepgram is the stable provider.

```env
VOICE_TYPE_PROVIDER=deepgram
VOICE_TYPE_LANGUAGE=ru
VOICE_TYPE_STATE_FILE=/tmp/voice-type-state.json
VOICE_TYPE_INSERT_METHOD=wayland-clipboard
DEEPGRAM_API_KEY=your-key
DEEPGRAM_MODEL=nova-3
VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS=10
VOICE_TYPE_AUTO_STOP_MIN_RECORD_SECONDS=2
VOICE_TYPE_AUTO_STOP_RMS_THRESHOLD=500
```

## F11 auto-stop on silence

For long dictation (`toggle-stream` / default F11), recording can stop automatically after a pause:

```env
VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS=10
VOICE_TYPE_AUTO_STOP_MIN_RECORD_SECONDS=2
VOICE_TYPE_AUTO_STOP_RMS_THRESHOLD=500
```

Set `VOICE_TYPE_AUTO_STOP_SILENCE_SECONDS=0` to disable auto-stop. F12 short/batch dictation stays manual. The Noctalia plugin settings expose this as **F11 auto-stop** with a 3–30 second pause slider; after changing it, run `noctalia-voice-type sync-noctalia-settings` so the CLI env receives the new value. During the silence pause, the bar indicator shows a countdown before auto-stop.

The first generated env file uses `ru` when system locale starts with `ru`, otherwise `en`.

## Sync from Noctalia plugin settings

The plugin settings UI can store provider/model/language/API key locally inside Noctalia settings. The CLI needs its own private env file, so after saving plugin settings run:

```bash
noctalia-voice-type sync-noctalia-settings
```

This command copies values into `~/.config/noctalia-voice-type/env` and never prints the API key.

If `DEEPGRAM_API_KEY` or `NOCTALIA_VOICE_TYPE_DEEPGRAM_API_KEY` is present in the Noctalia/Quickshell environment, the settings UI treats the key as environment-managed and does not show/store it.

## Diagnostics

```bash
noctalia-voice-type doctor --human
```

Checks:

- CLI executable on `PATH`;
- env file existence;
- `arecord`, `wl-copy`, `wtype`;
- stable provider selection;
- Deepgram API key presence;
- model/language/state-file/insert-method.

Secrets are never printed. Use `--strict` in scripts if you want non-zero exit when required checks fail:

```bash
noctalia-voice-type doctor --human --strict
```

## OpenRouter / OpenAI-compatible providers

Planned/experimental. The goal is to support gateways where a user can specify:

```env
VOICE_TYPE_PROVIDER=openrouter
OPENAI_COMPAT_BASE_URL=https://openrouter.ai/api/v1
OPENAI_COMPAT_API_KEY=your-key
OPENAI_COMPAT_MODEL=some/model-that-can-transcribe-audio
```

This is intentionally not stable yet: OpenAI-compatible chat gateways differ in how they accept audio files, and not every multimodal model is a good transcription model.
