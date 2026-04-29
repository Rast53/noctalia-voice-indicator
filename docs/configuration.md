# Configuration

Noctalia Voice Type must not ship with private API keys. Users provide their own provider credentials locally.

Recommended local config path:

```text
~/.config/noctalia-voice-type/env
```

Start from:

```bash
mkdir -p ~/.config/noctalia-voice-type
cp .env.example ~/.config/noctalia-voice-type/env
chmod 600 ~/.config/noctalia-voice-type/env
$EDITOR ~/.config/noctalia-voice-type/env
```

## Deepgram provider

```env
VOICE_TYPE_PROVIDER=deepgram
VOICE_TYPE_LANGUAGE=ru
DEEPGRAM_API_KEY=your-key
DEEPGRAM_MODEL=nova-3
```

Deepgram is the first implemented provider because it has a straightforward low-latency speech-to-text API and WebSocket streaming support.

## OpenRouter / OpenAI-compatible providers

Planned/experimental. The goal is to support gateways where a user can specify:

```env
VOICE_TYPE_PROVIDER=openrouter
OPENAI_COMPAT_BASE_URL=https://openrouter.ai/api/v1
OPENAI_COMPAT_API_KEY=your-key
OPENAI_COMPAT_MODEL=some/model-that-can-transcribe-audio
```

This is intentionally not marked stable yet: OpenAI-compatible chat gateways differ in how they accept audio files, and not every multimodal model is a good transcription model.

## Indicator state

```env
VOICE_TYPE_STATE_FILE=/tmp/voice-type-state.json
```

The Noctalia plugin reads this file. The CLI and future hotkey daemons write to it.

## Noctalia plugin settings

The Noctalia settings UI exposes the first STT provider settings directly:

- STT provider: Deepgram;
- STT model: default `nova-3`;
- language: default `ru`;
- Deepgram API key.

The key can also be managed by environment variable. If `DEEPGRAM_API_KEY` or `NOCTALIA_VOICE_TYPE_DEEPGRAM_API_KEY` is present in the Quickshell/Noctalia environment, the UI treats the key as environment-managed and does not show/store it in plugin settings.
