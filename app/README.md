# Navivox Flutter App

This is the Flutter package for Navivox, the Android-first operator app for trusted local or self-hosted Gormes agents. It is built for mobile chat, voice-first operation, safe gateway control, and user-visible Goncho memory inspection.

For product context and repo-level docs, start with `../README.md` and `../CONTEXT.md`.

## Development

```bash
flutter pub get
flutter test
flutter run
```

## Package Scope

This package owns the app UI and local client behavior:

- setup flow for a Gormes Navivox gateway
- profile contact and chat surfaces
- text and device-transcribed voice turns
- streaming assistant/system/tool UI
- safe connection, token, and recovery states
- Goncho memory dashboard surfaces backed by authenticated Gormes APIs
- memory health, safe counts, profile labels, and redacted database labels

Server-side agent execution, provider calls, tools, sessions, secrets, Goncho storage, and policy stay in Gormes. The Flutter app must not open `memory.db` directly.
