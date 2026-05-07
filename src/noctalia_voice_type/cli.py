from __future__ import annotations

import argparse
import sys

from .config import VoiceTypeConfig, DEFAULT_ENV_PATH
from .insert import insert_text
from .providers import build_provider
from .record import record_wav_until_enter
from .state import set_state
from .toggle import toggle


def cmd_transcribe_file(args: argparse.Namespace) -> int:
    config = VoiceTypeConfig.from_env()
    provider = build_provider(config)
    set_state(config.state_file, "processing")
    try:
        wav_bytes = open(args.path, "rb").read()
        text = provider.transcribe_wav(wav_bytes).strip()
        if text:
            set_state(config.state_file, "success")
            if args.insert:
                insert_text(text, config.insert_method)
            else:
                print(text)
        else:
            set_state(config.state_file, "ready")
        return 0
    except Exception as exc:
        set_state(config.state_file, "error", str(exc))
        raise
    finally:
        set_state(config.state_file, "ready")


def cmd_record_once(args: argparse.Namespace) -> int:
    config = VoiceTypeConfig.from_env()
    provider = build_provider(config)
    set_state(config.state_file, "recording")
    wav_bytes = record_wav_until_enter()
    set_state(config.state_file, "processing")
    try:
        text = provider.transcribe_wav(wav_bytes).strip()
        if text:
            set_state(config.state_file, "success")
            if args.insert:
                insert_text(text, config.insert_method)
            else:
                print(text)
        return 0
    except Exception as exc:
        set_state(config.state_file, "error", str(exc))
        raise
    finally:
        set_state(config.state_file, "ready")


def cmd_doctor(args: argparse.Namespace) -> int:
    config = VoiceTypeConfig.from_env()
    print(f"env_file={DEFAULT_ENV_PATH}")
    print(f"provider={config.provider}")
    print(f"language={config.language}")
    print(f"state_file={config.state_file}")
    print(f"insert_method={config.insert_method}")
    print(f"deepgram_model={config.deepgram_model}")
    print(f"deepgram_api_key_set={bool(config.deepgram_api_key)}")
    print(f"openai_compat_base_url_set={bool(config.openai_compat_base_url)}")
    print(f"openai_compat_api_key_set={bool(config.openai_compat_api_key)}")
    print(f"openai_compat_model={config.openai_compat_model or '<unset>'}")
    return 0


def cmd_toggle_batch(args: argparse.Namespace) -> int:
    return toggle("batch")


def cmd_toggle_stream(args: argparse.Namespace) -> int:
    # Streaming is currently implemented as the long-dictation toggle path. It keeps the
    # external F11/F12 semantics stable while provider-level streaming is developed.
    return toggle("stream")


def cmd_niri_snippet(args: argparse.Namespace) -> int:
    snippet = (
        "binds {\n"
        f"    {args.batch_key} allow-when-locked=false repeat=false {{\n"
        f"        spawn \"{args.command}\" \"toggle-batch\";\n"
        "    }\n\n"
        f"    {args.stream_key} allow-when-locked=false repeat=false {{\n"
        f"        spawn \"{args.command}\" \"toggle-stream\";\n"
        "    }\n"
        "}"
    )
    print(snippet)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="noctalia-voice-type")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("doctor", help="Print configuration diagnostics without secrets")
    p.set_defaults(func=cmd_doctor)

    p = sub.add_parser("transcribe-file", help="Transcribe an existing WAV file")
    p.add_argument("path")
    p.add_argument("--insert", action="store_true", help="Insert result into focused app")
    p.set_defaults(func=cmd_transcribe_file)

    p = sub.add_parser("record-once", help="Record with arecord until Enter, then transcribe")
    p.add_argument("--insert", action="store_true", help="Insert result into focused app")
    p.set_defaults(func=cmd_record_once)

    p = sub.add_parser("toggle-batch", help="Toggle short/batch dictation recording")
    p.set_defaults(func=cmd_toggle_batch)

    p = sub.add_parser("toggle-stream", help="Toggle long dictation recording")
    p.set_defaults(func=cmd_toggle_stream)

    p = sub.add_parser("niri-snippet", help="Print niri config snippet for configurable hotkeys")
    p.add_argument("--batch-key", default="F12", help="niri key spec for short/batch dictation")
    p.add_argument("--stream-key", default="F11", help="niri key spec for long/streaming dictation")
    p.add_argument("--command", default="noctalia-voice-type", help="command path used in niri spawn")
    p.set_defaults(func=cmd_niri_snippet)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
