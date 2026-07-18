# ADR 0006: Model Hermes runs as SSE-driven chat work with approvals and stop controls

Status: accepted
Date: 2026-07-07

## Context

Hermes supports both session chat streaming and `/v1/runs` with event streams. Runs can emit deltas, tool events, approval requests, terminal success/failure/cancel events, and stop requests. Hermes Agent 0.18 accepts `input`; older fixtures accepted `message`.

## Decision

For supported endpoints, Hermes Wing uses run transport for streamed work and treats SSE events as the source of live transcript state. Run events drive assistant deltas, bounded collapsed reasoning cards, tool progress rows, approval requests, terminal states, and server stop. The client sends both `input` and `message` when starting a run for compatibility across Hermes Agent versions. Each session owns its live stream, run id, completion gate, and approval routing, so selecting or starting another session does not detach the earlier run. ADR 0026 generalizes this HTTP-command and SSE lifecycle to other Hermes control-plane domains.

Ordinary Hermes requests have a bounded timeout, and an SSE stream that stays open without any activity is failed after a bounded idle interval so the UI cannot remain permanently stuck in a streaming turn.

## Consequences

- Every required scope declared by a chat, run, status, approval, stop, or session-mutation endpoint must be granted before Wing enables the operation or performs network I/O; legacy endpoint declarations with no scope metadata retain their existing compatibility behavior.
- `stopActiveTurn` stops only the selected session's server run when `/v1/runs/{run_id}/stop` is available and always cancels that session's local stream state; disconnect and profile replacement cancel every local stream without guessing server state.
- Approval requests carry their run and session identity. Switching sessions retains pending approvals, renders them only with their owning transcript, and routes responses to the originating run.
- Bounded `reasoning.available` text is treated as transcript activity, survives authoritative history reconciliation, and is exported without exposing unknown event payloads.
- SSE decoding, stream errors, dropped streams, and terminal events are core behavior and require tests.
- After a premature stream close, Wing may perform one exact capability-gated run-status read. A completed status can recover bounded output and token usage; queued/running status records a bounded opaque detached-run lease, suppresses duplicate retry across reconnects or process recreation for the same gateway/profile/session, and directs the operator to reconnect later. Reconnect releases the guard only after an exact terminal status. An unadvertised status route is never probed.
- Compatibility shims should be removed only after supported Hermes Agent versions converge.

## Edge cases

- Streams that close before a terminal event are failures unless reconciled by authoritative run status or server history.
- Approval events missing an approval id fail the active assistant turn instead of showing an unanswerable approval.
- Stale run submissions and disconnects must not mutate a newer connection. Session switches preserve attached streams, live local transcript state, and voice-run completion for the originating session.
- Background failures update only their owning transcript and session status; they do not replace the selected session's error banner.
- Detached-run leases contain only public gateway identity, profile/session/run handles, and creation time—never prompts, output, credentials, or transcripts. Production stores at most 16 leases in platform secure storage, expires them after Hermes Agent's one-hour status-retention window, and falls back to the in-process guard if secure storage fails.
- Local stop must still work when the server stop endpoint is absent.

## Evidence

- `README.md:20-24`
- `lib/core/hermes/channel/hermes_channel.dart:29-48`
- `lib/core/hermes/client/hermes_api_client.dart:173-214`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:24-30`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_approvals.dart`
- `lib/core/hermes/channel/hermes_detached_run_store.dart`
- `lib/core/hermes/setup/secure_hermes_detached_run_store.dart`
- `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart`
- `test/core/hermes/channel/hermes_api_channel_test.dart`
- `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`
