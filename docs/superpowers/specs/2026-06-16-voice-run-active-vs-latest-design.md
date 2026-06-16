# Voice Run: honest "active" vs "latest" semantics

Status: approved design
Date: 2026-06-16
Scope: Navivox Flutter app (client-local state model only)
Follows: `2026-05-20-voice-run-lifecycle-design.md`

## Problem

`NavivoxChannelState.activeVoiceRunId` is overloaded. It is meant to identify
the run currently *in flight*, but two behaviors make it also surface
*terminal* runs:

1. `cancelVoiceRun` / `failVoiceRun` upsert the terminal run with
   `active: true`, so `activeVoiceRunId` keeps pointing at a finished run.
2. The `activeVoiceRun` getter falls back to `voiceRuns.values.last` when
   `activeVoiceRunId` is null, so it surfaces the most recent run even if it is
   terminal.

This works today only because every in-flight consumer re-filters on
`status == NavivoxVoiceRunStatus.pendingSend`
(`local_command_dispatcher`, `profile_contact_conversation`,
`chat_screen_presentation`). The state model is not self-describing, the
coupling is fragile, and it will not scale to the planned non-terminal
server-voice statuses (`serverProcessing`, `agentTurnRunning`, `ttsReady`,
`playing`), which all legitimately mean "in flight".

Terminal statuses are `completed`, `cancelled`, `failed`
(`navivoxVoiceRunStatusIsTerminal`); `submitted` and all server-processing
statuses are non-terminal / in-flight.

## Design

Make the model state what it means: `activeVoiceRun` is the in-flight run and
nothing else; a separate accessor exposes the most-recent run for history and
evidence.

### 1. State policy is the single authority

`navivoxStateWithGatewayVoiceRun` decides activeness from the run itself
instead of trusting each caller's `active` flag for terminal transitions:

- When the upserted run `isTerminal` and it is the current active run, clear
  `activeVoiceRunId`.
- Otherwise honor the existing `active` flag (set to this run, or leave
  unchanged).

Effect: `startVoiceRun` (recording), `stageVoiceRunTranscript` (pendingSend),
and `submitVoiceRun` (submitted) keep the run active; `cancelVoiceRun` /
`failVoiceRun` (terminal) clear it. Callers are unchanged.

### 2. `activeVoiceRun` = in-flight only (self-guarding)

```text
activeVoiceRun => let run = voiceRuns[activeVoiceRunId]
                  (run != null && !run.isTerminal) ? run : null
```

Drop the `voiceRuns.values.last` fallback, and guard on `isTerminal` directly
in the getter rather than relying solely on the policy. This keeps the getter
honest for every channel, including the test doubles
(`TestNavivoxChannel`, `e2e_mock_channel`) which manage voice-run state outside
the gateway policy. Once a run finishes it returns null — no terminal run leaks
through, regardless of whether a given caller cleared the id.

### 3. Add `latestVoiceRun`

```text
latestVoiceRun => voiceRuns[activeVoiceRunId] (if set) else voiceRuns.values.last
```

This is the former `activeVoiceRun` fallback behavior, now named for what it is:
"the most recent run regardless of status."

### 4. Repoint the evidence inspector

`ProfileVoiceProfileCard._loadRunRecordEvidence` (and `evidencePlan`) consume
`latestVoiceRun` instead of `activeVoiceRun`, because inspecting run-record
evidence deliberately wants the last (often terminal) run.

### 5. Consequences

- `VoiceRunController.cancelPending`'s `?? activeVoiceRun?.id` fallback can no
  longer re-cancel a terminal run (it yields null when nothing is in flight).
- The per-consumer `pendingSend` filters become redundant safety nets rather
  than load-bearing logic. They are left in place (defensive, harmless) and are
  out of scope to remove.

## Non-goals

- No change to the `NavivoxVoiceRunStatus` enum or the terminal set.
- No change to channel send/submit wiring beyond what falls out of the policy.
- No removal of existing defensive `pendingSend` filters.
- No gateway/protocol change.

## Test strategy (TDD)

Add/extend Flutter tests, red first:

- Policy: upserting a terminal run clears `activeVoiceRunId`; upserting a
  non-terminal run (incl. `submitted`) keeps it active.
- Contract: `activeVoiceRun` is null after cancel/fail; `latestVoiceRun` still
  returns the terminal run.
- Channel: after `cancelVoiceRun`/`failVoiceRun`, `state.activeVoiceRun` is
  null and `state.latestVoiceRun` is the terminal run.
- Evidence: `evidencePlan(latestVoiceRun)` still resolves the last run's id.

Full `flutter analyze` + `flutter test` stay green.
