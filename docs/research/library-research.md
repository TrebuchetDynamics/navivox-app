# Navivox Library Research

Status: historical Gormes library research plus active Hermes-first addendum
Updated: 2026-07-03
Source: current root `pubspec.yaml`, active Hermes API/channel implementation, and preserved legacy gateway planning

## 1. Current Dependency Baseline

The app should stay small until a feature needs a package. The current
`pubspec.yaml` contains:

| Library | Purpose | Notes |
|---------|---------|-------|
| Flutter | App framework | Required. |
| `flutter_riverpod` | State management | Connection, channel, chat, voice, and route state. |
| `go_router` | Navigation | Setup redirect and shell tabs. |
| `uuid` | Client request ids | Used by channel messages and Hermes client-generated session/run ids. |
| `intl` | Formatting | Timestamps and durations. |
| `image_picker`, `mobile_scanner` | Legacy/import affordances | Preserved Gormes setup/import surfaces; not Hermes readiness receipts. |
| `path` | Path helpers | Local cache paths when needed. |
| `shared_preferences` | Non-secret local preferences | Stores safe endpoint/base URL metadata; never API keys. |
| `flutter_secure_storage` | Secret local storage | Stores Hermes API keys and durable credential secrets through secure-store paths. |
| `web` | Browser transport interop | Used by web-compatible Hermes HTTP/SSE transport. |
| `speech_to_text` | Local STT | Device transcript capture for local voice-to-text; not Hermes server audio. |
| `crypto` | Signing/hash helpers | Durable credential and protocol support. |

Dependencies removed from the current app should not be reintroduced as
planning defaults. Add packages only with the feature slice that needs them and
with tests proving the package participates in the current HTTP/WebSocket
gateway loop.

## 2. HTTP/SSE And Legacy WebSocket Transports

Active Hermes path: `HermesApiClient` uses platform-specific HTTP transports
for IO and web plus SSE/event decoding for session chat and run events
(`lib/core/hermes/client/hermes_api_client.dart`,
`lib/core/hermes/client/platform/`, `lib/core/hermes/sse/`). It supports
`GET`/`POST`/streaming `POST`/streaming `GET`/`PATCH`/`DELETE` so the native
Hermes channel can load capabilities, sessions, messages, health/catalog/jobs,
and session mutation actions without adding new third-party networking packages.

Preserved Gormes path uses `dart:io` `HttpClient` and `WebSocket`.

Current legacy gateway client responsibilities:

- Build `/healthz`, `/v1/navivox/status`, `/v1/navivox/sessions`,
  `/v1/navivox/turn`, and `/v1/navivox/stream` URLs from a base URL.
- Convert `http` to `ws` and `https` to `wss` for stream connections.
- Attach bearer auth headers when a token is configured.
- Decode JSON server events into typed Dart objects.
- Apply reconnect backoff.

Browser/web support for Hermes now uses the first-party `web` package and the
existing platform transport abstraction; do not add a cross-platform HTTP/SSE
package unless a source-backed slice proves the current IO/web split is
insufficient.

## 3. State And Navigation

### 3.1 Riverpod

Use Riverpod providers for:

- Active gateway channel.
- Connection state.
- Active server/session/agent.
- Chat message state.
- Config schema and draft state.
- Voice capture and transcript state.

Rules:

- Keep server-owned data separate from local UI drafts.
- Keep providers easy to override in tests.
- Avoid global singletons outside provider scopes.

### 3.2 GoRouter

Use GoRouter for:

- Setup redirect when no gateway-backed server is configured.
- Shell route for chat, servers, agents, and config.
- Future detail routes with stable path params.

Rules:

- Do not put tokens or secrets in route paths or query params.
- Detail routes should be mounted only when their screens work against the
  current gateway contract.

## 4. Chat UI

Active Hermes path keeps local Flutter widgets in `HermesChatScreen` for now.
It already renders session turns, approvals, tool progress, local-STT voice
transcripts, session management, read-only diagnostics, and readiness labels
without adding a chat UI dependency. Any package adoption must remain a
rendering layer over `HermesChannel` state and must not own Hermes transport,
credentials, persistence, or routing.

Historical Gormes plan: the planned chat foundation was
`flyerhq/flutter_chat_ui` v2, but the preserved app still uses local adapters.
Introduce a chat package only in the slice that needs:

- Streaming assistant text.
- Custom tool card builders.
- Voice message bubbles.
- Agent/system control messages.

Acceptance for adding the package:

- Existing connect-and-talk tests still pass.
- Tool events render through `ToolCallCard`.
- Raw tool JSON is not the default message UI.
- Long messages, mobile widths, and desktop widths are covered by screenshots
  or widget tests.

## 5. Secure Local Storage

Secure storage has landed for Hermes endpoint credentials and durable-key paths.
Continue using `flutter_secure_storage` for API keys/secrets and
`shared_preferences` only for non-secret endpoint metadata.

Requirements:

- Tokens are redacted in logs and UI.
- Clearing local app data removes persisted tokens.
- Linux failure modes show actionable setup errors.
- Route URLs and deep links never contain tokens.

Until secure storage lands, tests should prefer injected in-memory credentials.

## 6. Local Unlock

Use local biometric/PIN packages only for local unlock flows:

- Secret editor access.
- Viewing redacted-sensitive metadata.
- Applying high-risk config mutations.

The server still decides whether a user can mutate config. Local unlock is an
extra client-side gate, not authorization by itself.

## 7. Voice And Audio

Voice features should be added in thin slices.

Candidate package categories:

- Microphone capture.
- Platform STT for local transcript hints.
- Audio playback for server-generated speech.
- Permission prompts.

Current rule:

- The first connect-and-talk loop may submit a local transcript through the text
  turn path.
- Audio upload, server STT profiles, and TTS playback require Voice run
  lifecycle state first.

## 8. Generated Models

Use generated immutable models when gateway/config/voice DTOs become too large
for hand-written classes.

Good candidates:

- Gateway events with many variants.
- Config schema field types.
- Agent draft/profile/tool/voice settings.
- Voice run lifecycle models.

Rules:

- Generated files and build steps must be documented.
- Tests must prove unknown server fields do not crash the app.
- Secret fields must not be serializable into logs by accident.

## 9. Persistence

Local persistence is a cache, not authority. Add a database only when one of
these needs exists:

- Offline session list.
- Searchable message history.
- Durable Voice run history.
- Cached config schema snapshots.
- Agent draft recovery.

Before adding a database, define:

- Retention policy.
- Clear-local-data behavior.
- Migration strategy.
- Redaction policy for sensitive tool output and transcripts.

## 10. Config UI Packages

Schema-driven config can start with first-party Flutter form widgets.
Introduce form-builder packages only if they remove real complexity.

Required form behavior:

- Field-level server validation mapping.
- Redacted secret status.
- Diff preview.
- Confirmation for risky changes.
- Pending restart/reconnect result.

## 11. Known Limitations And Workarounds

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Dart IO client is not browser-compatible | Web builds need another client layer | Defer web support to a dedicated slice. |
| Local STT varies by platform | Voice may be text-only on some devices | Always keep text turn fallback. |
| Secure storage can fail on minimal Linux installs | Persisted tokens may not be available | Show setup error and allow in-memory session. |
| Audio playback adds platform-specific behavior | TTS tests can become flaky | Start with voice run metadata before streaming audio. |
| Generated model build steps add maintenance | CI and contributors need setup | Add only when protocol shape requires it. |

## 12. Package Addition Checklist

Before adding a dependency:

1. Name the feature slice that requires it.
2. Prove it supports the target platforms for that slice.
3. Add tests or fixtures that exercise it.
4. Document failure modes.
5. Confirm it does not expand the first activation loop beyond connect and talk.
