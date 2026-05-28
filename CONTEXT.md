# Navivox Context

Navivox is the operator-facing Flutter app for talking to trusted local or self-hosted Gormes profiles. This context keeps product language stable while architecture work deepens modules around the connect-and-talk loop.

## Language

**Navivox**:
The Flutter operator app that connects to a Gormes gateway and presents profile chat, voice input, tool activity, and safe config flows.
_Avoid_: generic chat client, server admin panel

**Gormes gateway**:
The server-side Navivox endpoint that owns agents, sessions, tools, config, secrets, provider execution, and the HTTP/WebSocket event stream.
_Avoid_: backend, remote shell

**Pairing handoff**:
The first-run transfer of Gormes gateway connection details from Gormes or Termux to Navivox, completed only when Navivox successfully connects to the Gormes gateway.
_Avoid_: QR flow, connect-info flow, login

**Pairing handoff source**:
How Navivox received a **Pairing handoff**, such as direct app open from Gormes, shared text, QR/image import, or manual entry. The source affects how much operator confirmation is required before Navivox probes or switches a **Gormes gateway**.
_Avoid_: QR type, intent action, trust level

**Profile contact**:
A flat chat-list identity made from one `server_id` plus one `profile_id`.
_Avoid_: agent, user account, thread

**Gateway identity**:
A stable opaque-public identity for recognizing the same **Gormes gateway** across changed connection details.
_Avoid_: Profile contact server_id, base URL, bearer token, display name

**Durable reconnect credential**:
A Gormes-issued, revocable credential that lets Navivox reconnect to a known **Gormes gateway** after a completed **Pairing handoff**. It is distinct from the Pairing handoff token and must not be stored in shared preferences or shown in normal UI.
_Avoid_: saved token, persisted pairing token, remember-me password

**Reconnect readiness**:
The operator-visible state describing whether Navivox can save or use durable reconnect for a **Gormes gateway**. It is separate from active session connectivity and from **Voice readiness**.
_Avoid_: login status, saved session, remember-me state

**Profile contact conversation**:
The scoped communication state for one **Profile contact**, including visible transcript items, pending voice state, Gormes turn metadata, and stream attribution for that contact.
_Avoid_: global chat log, unscoped message history, selected agent chat

**Transcript surface**:
The chat area that shows user turns, assistant turns, tool activity, safety notices, approval prompts, voice transcript bubbles, the composer, and message action sheets for the active **Profile contact**.
_Avoid_: generic message list, log viewer, terminal output

**Command word**:
The local prefix, default `navi`, that marks a message or utterance as a Navivox command.
_Avoid_: wake word, hotword

**Local command**:
A typed message or voice utterance that starts with the command word and is handled by Navivox without being sent as a Gormes turn.
_Avoid_: chat message, server command, tool call

**Operator intent**:
A local Navivox UI action emitted by the **Transcript surface**, such as send text, submit voice transcript, forward message, or inspect tool activity. The app shell or screen decides how that intent affects routing, the active **Profile contact**, or the **Gormes gateway**.
_Avoid_: callback, command, server event

**Navigation intent**:
A subtype of **Operator intent** that names the destination an operator wants to reach. Examples: open-agents, open-workspace, open-config, open-settings, manage-gateways, open-chat-thread. A **Navigation intent** module translates these to GoRouter routes.
_Avoid_: route path, AppRoutes constant, GoRouter call

**Voice run**:
One end-to-end Navivox voice interaction, from capture through transcript, optional server STT, agent turn, optional server TTS, playback, cancellation, errors, and retention policy.
_Avoid_: audio blob, transcript string, voice message

**Voice readiness**:
The per-**Profile contact** operator-visible state that says whether Navivox can start a **Voice run** now, and the blocking reason or recovery action when it cannot. It combines shared local device conditions with active **Profile contact** and **Gormes gateway** conditions.
_Avoid_: mic enabled, STT flag, voice status

**Run record**:
A **Gormes gateway**-owned, redacted operator evidence snapshot for a submitted turn or session. A **Run record** may include transcript, voice, tool, provider usage, cost, and retention evidence; it is not the client-local **Voice run** lifecycle and not raw developer diagnostics. The **Gormes gateway** owns redaction before Navivox receives the snapshot, and Navivox presents only allowlisted evidence fields by default.
_Avoid_: voice run record, debug log, raw trace, debug dump

**Run record reference**:
An opaque **Gormes gateway**-supplied handle that Navivox can pass back to load a **Run record**. A **Run record reference** may be backed by a run id, session id, or request id, but Navivox does not infer or parse its type from transcript display ids.
_Avoid_: message id, row id, guessed run id

## Relationships

- **Navivox** connects to one or more **Gormes gateways**.
- A **Pairing handoff** gives Navivox the connection details for a **Gormes gateway**.
- A **Pairing handoff source** determines whether Navivox may try the handoff immediately or must wait for operator confirmation.
- A **Gormes gateway** has one **Gateway identity**.
- A **Durable reconnect credential** is scoped to one authenticated **Gateway identity** and is not the **Pairing handoff** token.
- **Reconnect readiness** may be unavailable even when a **Pairing handoff** succeeds and chat works for the current app session.
- A **Gormes gateway** reports zero or more **Profile contacts**.
- A **Profile contact** is the target for chat turns and voice turns.
- A **Profile contact conversation** belongs to one **Profile contact**; Navivox must not show another Profile contact's scoped transcript items in the active **Transcript surface**.
- The **Transcript surface** renders the active **Profile contact** conversation, keeps tool activity distinct from ordinary assistant text, and owns composer/action-sheet behavior.
- A **Local command** uses the **Command word** and produces a local intent for Navivox to execute.
- The **Transcript surface** emits **Operator intents** upward instead of owning Gormes gateway calls or route changes.
- **Voice readiness** determines whether the **Transcript surface** can start a **Voice run** for the active **Profile contact**.
- Full **Voice readiness** is scoped to the active chat only; Profile contact lists may show simple profile-reported health or mic hints, but should not precompute combined trust, device, or session readiness for every contact.
- **Voice readiness** is not persisted; Navivox recomputes it on app start, active **Profile contact** changes, voice settings or trust changes, runtime capture failures that prove a capability is unavailable, and app resume. Shared device readiness is only one input.
- **Voice readiness** blocker priority is local Navivox intent first, then device setup, then gateway/profile conditions: settings disabled, no **Profile contact**, untrusted **Gormes gateway**, unavailable Android speech recognizer, microphone permission denied, gateway profile STT unavailable, **Profile contact** not online, then profile mic unavailable.
- When Android speech recognition and microphone permission are both unavailable, **Voice readiness** shows the missing recognizer as the primary blocker because permission alone cannot make voice work; diagnostics may still show microphone permission as denied.
- A pre-capture Android diagnostic that microphone permission is not granted is not a **Voice readiness** blocker by itself; the first capture may trigger Android's permission prompt. It may appear in Voice diagnostics as "not granted yet" while **Voice readiness** remains ready. Microphone permission blocks **Voice readiness** only after the speech capture path reports a capability-proving permission denial.
- Voice diagnostics should show actionable Android/gateway states, not raw Android recognizer service names or service counts.
- An untrusted **Gormes gateway** outranks device setup blockers in **Voice readiness** because trust is a product safety gate; device readiness can still appear in diagnostics.
- While device speech checks are loading, **Voice readiness** is checking rather than unavailable; Navivox should not start a **Voice run**, but should avoid showing a false failure.
- Runtime failures disable **Voice readiness** for the session only when they prove voice cannot work, such as unavailable device STT or denied microphone permission.
- Timeout, no speech, and generic capture failure fail the current **Voice run** but should not permanently disable **Voice readiness**.
- **Voice readiness** gates starting voice input only; TTS and playback readiness are downstream **Voice run** state and should not block capture.
- A **Voice run** is product state, not just a transcript string; it may produce a Gormes turn and later playback state.
- A submitted text or voice turn may have a **Run record**.
- A cancelled-before-send **Voice run** has no **Run record**.
- A submitted **Voice run** may be linked to a **Run record** by the **Gormes gateway**.
- Visible transcript items expose **Run record** inspection only when the **Gormes gateway** supplies a **Run record reference** for that item; display row identity is not enough.
- The **Gormes gateway** redacts **Run records** before Navivox receives them.
- Navivox presents allowlisted **Run record** evidence fields by default and does not treat raw gateway JSON as normal operator UI.
- **Run record** inspection is a normal operator evidence action, not a developer-only debug path.
- **Run records** should show identity, status, timeline, transcript evidence, tool evidence, applicable voice evidence, and provider usage/cost state.
- **Run records** may show redacted or aggregated provider cost evidence from the **Gormes gateway**, but not billing-account details, raw provider invoices, API keys, or provider credentials.
- **Run records** may show redacted memory provenance or references when supplied by the **Gormes gateway**, but detailed memory inspection belongs to the memory console.
- **Run records** should not show raw prompts, full tool payloads, provider request/response JSON, stack traces, IP addresses, user agents, raw memory database rows, or fabricated zero usage/cost in normal UI.
- **Run record** inspection is available only when the **Gormes gateway** advertises Run record support and supplies a **Run record reference** for a transcript item.
- A **Run record reference** may apply to any transcript item kind; it is not specific to text, voice, tool, safety, or approval rendering.
- Operator copy should describe **Run record** inspection as viewing evidence; "Evidence" is the preferred panel title, while "Run record" remains technical domain language.
- A failed **Run record** lookup is an evidence lookup failure, not conversation transcript state; Navivox should show transient recovery UI rather than append a chat message.
- A **Local command** may switch the active **Profile contact**, cancel or stop work, open settings, or show help.
- A **Local command** is not a Gormes turn and must not be forwarded to the **Gormes gateway** as chat text.

## Example dialogue

> **Dev:** "If the operator types `navi mineru`, should the Gormes gateway receive that as chat text?"
> **Domain expert:** "No. That is a **Local command**. Navivox should parse it locally, switch to the matching **Profile contact**, and send nothing to the gateway."
>
> **Dev:** "If a voice capture is cancelled before send, can the operator inspect its **Run record**?"
> **Domain expert:** "No. The cancelled capture is a local **Voice run** only. A **Run record** exists after the **Gormes gateway** has evidence for a submitted turn or session."

## Flagged ambiguities

- "profile", "agent", and "contact" can drift together. Resolved: use **Profile contact** for the `server_id + profile_id` chat-list identity; use agent only for server-owned runtime behavior.
- "wake word" can imply always-listening audio. Resolved: use **Command word** for the local prefix active only in Navivox text or voice command mode.
- "message list" can imply a passive log. Resolved: use **Transcript surface** for the active chat UI area because it renders tool activity, safety notices, approval prompts, and voice transcript bubbles as product state.
- "voice message" can imply a single rendered bubble. Resolved: use **Voice run** for the full lifecycle and reserve voice bubble wording for Transcript surface rendering.
- "mic enabled", "STT flag", and "voice status" each describe only part of the gate. Resolved: use **Voice readiness** for the combined operator-visible ability to start a **Voice run** now.
- "voice run record" blurs local lifecycle state with gateway evidence. Resolved: use **Voice run** for the Navivox voice lifecycle and **Run record** for a redacted gateway evidence snapshot.
- "message id" can mean a display row identity rather than gateway evidence identity. Resolved: **Run record** inspection requires a Gormes-supplied **Run record reference**, not arbitrary transcript row ids.
- "run id", "session id", and "request id" can describe storage details behind evidence lookup. Resolved: use **Run record reference** at the Navivox product boundary.
- "login", "QR flow", and "connect-info flow" can imply separate setup products. Resolved: use **Pairing handoff** for the first-run transfer of Gormes gateway connection details, with direct Android link as the preferred path and QR/shared text/manual entry as fallbacks. Receiving fields is not completion; successful connection is completion.
- "server" can mean the **Gormes gateway** or the `server_id` half of a **Profile contact**. Resolved: use **Gateway identity** for recognizing a Gormes gateway; keep Profile contact `server_id` scoped to profile/contact routing.
