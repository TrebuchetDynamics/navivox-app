# Architecture Decision Records

Navivox ADRs record durable decisions for the active Hermes-only app. They are source-backed snapshots, not migration task lists.

- [ADR 0001: Make Navivox a Hermes-only companion](0001-hermes-only-runtime.md)
- [ADR 0002: Use Riverpod providers for app seams and test overrides](0002-riverpod-provider-seams.md)
- [ADR 0003: Route through a small Hermes and Settings shell](0003-go-router-hermes-settings-shell.md)
- [ADR 0004: Store Hermes endpoint metadata separately from API keys](0004-hermes-endpoint-and-secret-storage.md)
- [ADR 0005: Gate Hermes surfaces with the capabilities document](0005-capability-gated-hermes-client.md)
- [ADR 0006: Model Hermes runs as SSE-driven chat work with approvals and stop controls](0006-run-sse-approvals-and-stop-lifecycle.md)
- [ADR 0007: Keep a native HermesChannel instead of a legacy NavivoxChannel adapter](0007-native-hermes-channel-not-navivox-channel-adapter.md)
- [ADR 0008: Build a mobile Hermes UI with Telegram chat ergonomics](0008-mobile-hermes-ui-with-telegram-ergonomics.md)
- [ADR 0009: Use local device STT and TTS packages for voice](0009-local-device-voice-stt-tts.md)
- [ADR 0010: Validate with Flutter unit tests plus web/E2E Hermes entry points](0010-validation-and-e2e-entrypoints.md)
