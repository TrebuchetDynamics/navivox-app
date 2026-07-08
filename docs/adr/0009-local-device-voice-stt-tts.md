# ADR 0009: Use local device STT and TTS packages for voice

Status: accepted
Date: 2026-07-07

## Context

Navivox voice is local to the client install. The app now depends on `speech_to_text` for speech-to-text and `flutter_tts` for text-to-speech. Hermes receives submitted text transcripts; it does not need client-recorded audio for the active workflow.

## Decision

Use local device packages for voice:

- `speech_to_text` captures user speech as a text transcript.
- `flutter_tts` speaks assistant replies when the platform supports it.
- Voice package support is platform-gated. Unsupported platforms return `null` providers and the UI pauses continuous voice with plain-language feedback.
- Do not log raw recognized speech text in diagnostics.

## Consequences

- Server audio APIs remain out of scope until Hermes exposes stable mobile-safe endpoints.
- Tests use injectable engine interfaces and fake services rather than real microphones or speakers.
- Linux can still build the app; runtime TTS is disabled there because `flutter_tts` has no Linux plugin support.

## Edge cases

- Unsupported platforms return `null` services and the UI pauses continuous voice instead of crashing.
- Blank captured transcripts fail locally before reaching Hermes.
- TTS ignores blank assistant text and retries configuration after a failed setup call.
- Speech diagnostics log metadata, not raw recognized words.

## Evidence

- `pubspec.yaml:18-19`
- `lib/features/hermes_chat/screens/hermes_chat_screen.dart:37-44`
- `lib/features/voice/services/platform/default_voice_capture_service.dart:15-33`
- `lib/features/voice/services/speech/speech_to_text_voice_capture_service.dart:17-99`
- `lib/features/voice/services/tts/text_to_speech_service.dart:1-111`
- `test/features/voice/services/speech/speech_to_text_voice_capture_service_test.dart`
- `test/features/voice/services/tts/text_to_speech_service_test.dart`
