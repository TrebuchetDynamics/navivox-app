# Build a native Hermes channel instead of a `HermesNavivoxChannel` adapter

Status: accepted

Amends: [ADR 0006 — Make Navivox Hermes Agent-first](0006-hermes-agent-first-runtime.md)

## Context

ADR 0006 and [the Hermes Agent interface plan](../product/hermes-agent-interface-plan.md) proposed a transition seam: implement `HermesNavivoxChannel implements NavivoxChannel` so existing Gormes-era screens (profile contacts, config-admin, Goncho memory, profile seed, voice profiles, run-record inspection, profile routing) could keep compiling while the data source swapped to Hermes.

`NavivoxChannel` (`lib/core/channel/contracts/navivox_channel.dart`) is a ~35-member interface shaped entirely around the Gormes `/v1/navivox/*` domain model: profile contacts, config-admin diff/validate/apply, Goncho memory overview/search/detail/action, profile seed, voice-profile validation, run-record snapshots, profile routing selection. Hermes Agent's API server has no equivalent for most of these. Forcing a Hermes implementation to satisfy that interface means either throwing `UnsupportedError` from roughly two-thirds of the interface indefinitely, or quietly reinventing Gormes-shaped concepts (profile contacts, config-admin) against an API that was never designed to have them.

On review, the owner rejected the adapter approach directly: Navivox should adapt its domain model to Hermes, not force Hermes to answer to a Gormes-shaped interface, and should lean heavily on `fathah/hermes-desktop`'s own architecture (renderer/session store shape, `sse-parser.ts`/`run-stream.ts` decoding, capability-gated transport, chat voice input) as the reference for how a Hermes-native client should be structured, rather than reusing Navivox's Gormes-era abstractions by default.

## Decision

Do not implement `HermesNavivoxChannel implements NavivoxChannel`. Instead, build a small, Hermes-native channel abstraction sized to what Hermes Agent's API server actually exposes:

- A new `HermesChannel` interface (name TBD at implementation time, e.g. `lib/core/hermes/channel/hermes_channel.dart`) covering only: connect/disconnect, session list/create/select, send text turn, session chat streaming, the voice-run lifecycle (`startVoiceRun`/`stageVoiceRunTranscript`/`submitVoiceRun`/`cancelVoiceRun`/`failVoiceRun` — reusing the already-generic `NavivoxVoiceRun` model, which has no Gormes-specific fields), cancel/stop active turn, and respond-to-approval once run transport lands.
- A parallel `HermesChannelState` shaped around Hermes sessions/messages, not `NavivoxChannelState`'s servers/profile-contacts/config-admin/memory fields.
- No compatibility shim satisfying the old 35-member interface. Gormes-only screens (config-admin, Goncho memory, profile seed, voice-profile validation, run-record inspection, profile routing) are not wired to Hermes at all; they stay reachable only through `GatewayNavivoxChannel` on the recoverable `gormes` branch, not on Hermes-first `main`.
- New Navivox screens for chat/sessions/continuous voice are built against `HermesChannel` directly, following hermes-desktop's structure for reference (explicit client session IDs, capability-gated run transport, SSE parsing as a pure/testable seam, end-of-stream reconciliation against `GET /api/sessions/{id}/messages`), not by relabeling the old profile-contact UI.

## Consequences

- `lib/core/hermes/` (client, models, SSE decoder, transport policy) is reused as-is; it already has no Gormes coupling.
- The full `NavivoxChannel` interface and `GatewayNavivoxChannel` remain in place, used only by the preserved Gormes runtime; they are not extended or partially implemented for Hermes.
- Existing Gormes-era screens (profile contacts, config-admin, memory, profile seed, voice profiles, run-record) do not light up under Hermes mode and are not expected to; they are out of scope until/unless Hermes exposes an equivalent API, matching the interface plan's "Out of MVP"/"Later" surface table.
- `VoiceRunController` (`lib/features/chat/voice/controllers/voice_run_controller.dart`) is `NavivoxChannel`-typed today; a Hermes-side continuous-voice controller needs its own small typed sink (or a shared structural interface over just the voice-run methods) rather than depending on `NavivoxChannel`.
- The delivery slice order in the interface plan changes: slice 3 becomes "native `HermesChannel` + Hermes chat/session screens" instead of "`HermesNavivoxChannel` adapter behind old screens." The plan doc will be updated to match.
