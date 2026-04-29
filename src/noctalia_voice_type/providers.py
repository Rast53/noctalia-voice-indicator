from __future__ import annotations

from abc import ABC, abstractmethod
import urllib.parse

import requests

from .config import VoiceTypeConfig


class TranscriptionProvider(ABC):
    @abstractmethod
    def transcribe_wav(self, wav_bytes: bytes) -> str:
        raise NotImplementedError


class DeepgramProvider(TranscriptionProvider):
    def __init__(self, config: VoiceTypeConfig):
        if not config.deepgram_api_key:
            raise RuntimeError(
                "DEEPGRAM_API_KEY is not set. Put it in ~/.config/noctalia-voice-type/env "
                "or export it in the session."
            )
        self.config = config

    def transcribe_wav(self, wav_bytes: bytes) -> str:
        query = urllib.parse.urlencode(
            {
                "model": self.config.deepgram_model,
                "language": self.config.language,
                "punctuate": "true",
                "smart_format": "true",
            }
        )
        url = f"https://api.deepgram.com/v1/listen?{query}"
        headers = {
            "Authorization": f"Token {self.config.deepgram_api_key}",
            "Content-Type": "audio/wav",
            "Connection": "close",
        }
        last_error: Exception | None = None
        for attempt in range(1, 4):
            try:
                resp = requests.post(url, headers=headers, data=wav_bytes, timeout=45)
                if resp.status_code == 200:
                    data = resp.json()
                    return (
                        data.get("results", {})
                        .get("channels", [{}])[0]
                        .get("alternatives", [{}])[0]
                        .get("transcript", "")
                    )
                last_error = RuntimeError(f"Deepgram HTTP {resp.status_code}: {resp.text[:300]}")
            except Exception as exc:  # network retry
                last_error = exc
        raise last_error or RuntimeError("Deepgram transcription failed")


class OpenAICompatibleProvider(TranscriptionProvider):
    """Placeholder for OpenRouter/OpenAI-compatible multimodal transcription.

    Different OpenAI-compatible gateways expose audio input differently. We keep this explicit
    instead of pretending every chat model can transcribe WAV reliably.
    """

    def __init__(self, config: VoiceTypeConfig):
        self.config = config
        raise NotImplementedError(
            "OpenAI-compatible/OpenRouter transcription provider is planned but not implemented yet. "
            "Use VOICE_TYPE_PROVIDER=deepgram for now."
        )

    def transcribe_wav(self, wav_bytes: bytes) -> str:
        raise NotImplementedError


def build_provider(config: VoiceTypeConfig) -> TranscriptionProvider:
    if config.provider == "deepgram":
        return DeepgramProvider(config)
    if config.provider in {"openai-compatible", "openrouter"}:
        return OpenAICompatibleProvider(config)
    raise RuntimeError(f"Unsupported VOICE_TYPE_PROVIDER={config.provider!r}")
