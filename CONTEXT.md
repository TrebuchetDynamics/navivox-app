# Navivox Context

Navivox is transitioning on `main` into the operator-facing Flutter companion app for trusted local or self-hosted Hermes Agent sessions. The preserved Gormes-first app state lives on the `gormes` branch; this context keeps new Hermes product language stable while architecture work deepens modules around the connect-and-talk loop.

## Language

**Navivox**:
The Flutter operator app that connects to a Hermes Agent API server and presents session chat, local voice input, tool activity, approvals, and safe connection/config status.
_Avoid_: generic chat client, server admin panel

**Hermes endpoint**:
The trusted local, LAN, VPN, or self-hosted Hermes Agent API server Navivox talks to directly over HTTP/SSE.
_Avoid_: Gormes gateway, backend, remote shell

**Hermes session**:
A durable Hermes Agent conversation returned by `/api/sessions` and used as the main chat lane in Navivox.
_Avoid_: Profile contact, thread, agent account

**Hermes API key**:
The bearer secret for a Hermes endpoint when `API_SERVER_KEY` is configured. Navivox stores it only in secure storage and never in shared preferences, logs, routes, notices, or transcript state.
_Avoid_: pairing token, durable reconnect credential, saved token

**Hermes Desktop reference**:
The upstream Hermes Desktop app used as product and UX inspiration for Navivox surfaces and transport-gating behavior. It is reference material, not the source of mobile product scope; Hermes Agent's API server is the runtime target.
_Avoid_: copying Electron install/update mechanics, preserving Gormes terms

**Gormes gateway**:
Legacy preserved-branch runtime term for the old `/v1/navivox/*` gateway. Do not introduce new mainline product work around this boundary unless explicitly maintaining the `gormes` branch.
_Avoid_: using as a synonym for Hermes endpoint

**Pairing handoff**:
Legacy Gormes-path first-run transfer of gateway connection details from Gormes or Termux to Navivox, completed only when Navivox successfully connects to the Gormes gateway. New Hermes setup uses **Hermes endpoint** connection language instead.
_Avoid_: QR flow, connect-info flow, login, Hermes login

**Pairing handoff source**:
How Navivox received a **Pairing handoff**, such as direct app open from Gormes, shared text, QR/image import, or manual entry. The source affects how much operator confirmation is required before Navivox probes or switches a **Gormes gateway**.
_Avoid_: QR type, intent action, trust level

**Pairing readiness**:
The operator-visible state describing whether Navivox is waiting for **Pairing handoff** details, reviewing an imported handoff, connecting to the **Gormes gateway**, connected for the current app session, or blocked with a retryable pairing problem. It is separate from **Reconnect readiness**, **Gateway status**, and durable credential storage.
_Avoid_: login status, setup error, saved session status, durable reconnect status

**Profile contact**:
A flat chat-list identity made from one `server_id` plus one `profile_id`.
_Avoid_: agent, user account, thread

**Profile seed**:
A natural-language operator request for the **Gormes gateway** to draft **Profile contact** configuration. Suggested workspace roots in the draft are not granted until the operator types or explicitly confirms the workspace choice in Navivox.
_Avoid_: profile template, automatic workspace grant, TOML editor

**Gateway identity**:
A stable opaque-public identity for recognizing the same **Gormes gateway** across changed connection details.
_Avoid_: Profile contact server_id, base URL, bearer token, display name

**Gateway status**:
The operator-visible status summary for a **Gormes gateway** using safe currently reported facts: active app-session state, gateway-reported status, **Profile contact** counts/attention, and an explicit note when base URL, auth, exposure, stream health, credentials, or local trust metadata is not available. It must not expose tokens or fabricate unavailable connection metadata.
_Avoid_: raw server status, healthz dump, credential detail, inferred exposure

**App install identity**:
A non-secret random identity for one Navivox installation. It is distinct from a device fingerprint, user account, **Gateway identity**, or credential ID.
_Avoid_: device ID, hardware ID, Android account, credential ID

**Local settings**:
Operator preferences scoped to one Navivox install, such as command word, local voice capture defaults, and local voice trust. They may reference the active **Gormes gateway** or **Profile contact**, but they do not mutate Gormes-owned config, **Voice profile**, gateway auth, or durable reconnect credentials.
_Avoid_: Gormes settings, profile config, server config, saved session

**Known gateway metadata**:
Non-secret saved connection metadata that helps Navivox recognize or prefill a previously connected **Gormes gateway**. It is not a saved session and cannot silently reconnect without a **Durable reconnect credential**.
_Avoid_: saved session, cached login, stored token

**Durable reconnect credential**:
A Gormes-issued, revocable credential that lets Navivox reconnect to a known **Gormes gateway** after a completed **Pairing handoff**. It is distinct from the Pairing handoff token and must not be stored in shared preferences or shown in normal UI.
_Avoid_: saved token, persisted pairing token, remember-me password

**Reconnect readiness**:
The operator-visible state describing whether Navivox can save or use durable reconnect for a **Gormes gateway**. It is separate from active session connectivity and from **Voice readiness**.
_Avoid_: login status, saved session, remember-me state

**Config readiness**:
The operator-visible state describing whether Navivox can load and safely present Gormes config-admin for the active **Gormes gateway** and **Profile contact**, and the blocking reason or recovery action when it cannot. It is separate from **Voice profile** availability, local app settings, and **Voice readiness**.
_Avoid_: no config available, settings status, voice profile status, empty config

**Memory readiness**:
The operator-visible state describing whether Navivox can load and safely present Gormes-owned Goncho memory for the active **Gormes gateway** and **Profile contact**, and the blocking reason or recovery action when it cannot. It is separate from **Config readiness**, **Voice readiness**, and raw memory database health.
_Avoid_: Goncho degraded, memory API unavailable, empty memory, database status

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

**Pairing intent**:
A subtype of **Operator intent** emitted by setup and pairing surfaces when the operator submits, imports, retries, confirms, or rejects a **Pairing handoff**. It carries the handoff source and operator choice without exposing pairing tokens as normal UI state.
_Avoid_: form callback, connect button handler, login action

**Voice profile**:
Per-**Profile contact** **Gormes gateway** configuration for STT/TTS providers, voice identity, language policy, fallback behavior, and write-only voice credentials. It is config state, not **Voice run** evidence.
_Avoid_: voice run settings, local mic permission, raw provider credentials

**Voice run**:
One end-to-end Navivox voice interaction, from capture through transcript, optional server STT, agent turn, optional server TTS, playback, cancellation, errors, and retention policy. In the current Hermes path this is local device STT submitted as a Hermes text turn; Hermes realtime/server audio is not implemented.
_Avoid_: audio blob, transcript string, voice message, server audio receipt

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

- **Navivox** connects to one trusted **Hermes endpoint** for the first Hermes MVP; multi-endpoint management can follow later and is deferred/read-only until explicitly implemented.
- Operator-facing connection surfaces should label the target as a Hermes endpoint or Hermes Agent server, not a Gormes gateway.
- **Hermes sessions** are the main conversation list and replace Profile contacts in new product language.
- **Hermes API keys** are secret connection credentials and must stay out of shared preferences, logs, routes, notices, transcript state, screenshots, and diagnostics exports.
- A **Hermes Desktop reference** may inform Navivox app shape and transport-gating behavior, but Navivox should not copy Electron install/update mechanics or old Gormes domain terms.
- Hermes config admin, memory UI, jobs/schedules admin, messaging gateways, persona/SOUL, attachments/media, files/context folders, raw diagnostics/log export, and multi-endpoint/profile management are deferred/read-only in the current Hermes MVP unless a source-backed implementation changes that status.
- A **Pairing handoff** gives Navivox the connection details for a **Gormes gateway**.
- A **Pairing handoff source** determines whether Navivox may try the handoff immediately or must wait for operator confirmation.
- **Pairing readiness** belongs to the setup and pairing surfaces; a ready or connected **Pairing readiness** state does not imply durable reconnect is available.
- A **Gormes gateway** has one **Gateway identity**.
- An **App install identity** scopes one Navivox installation without identifying the physical device or operator account.
- **Local settings** belong to one Navivox install; they can influence **Voice readiness** and local navigation behavior but do not update Gormes config, **Voice profile**, **Gateway status**, or **Reconnect readiness**.
- **Known gateway metadata** may identify a previously connected **Gormes gateway**, but only a **Durable reconnect credential** can authorize silent reconnect.
- A **Durable reconnect credential** is scoped to one authenticated **Gateway identity** and one **App install identity**, and is not the **Pairing handoff** token.
- **Reconnect readiness** may be unavailable even when a **Pairing handoff** succeeds and chat works for the current app session.
- **Config readiness** belongs to the active **Gormes gateway** and selected **Profile contact** scope; unavailable **Config readiness** does not imply chat, **Voice readiness**, or **Voice profile** is unavailable.
- **Memory readiness** belongs to the active **Gormes gateway** and selected **Profile contact** scope; unavailable **Memory readiness** does not imply chat, **Config readiness**, or **Voice readiness** is unavailable.
- A **Gormes gateway** reports zero or more **Profile contacts**.
- Operator-facing profile selection and management surfaces should label this identity as profiles or **Profile contacts**, not agents.
- A **Profile seed** may ask the **Gormes gateway** to draft a **Profile contact**, but Navivox does not grant suggested workspace roots without operator confirmation.
- A **Profile contact** is the target for chat turns and voice turns.
- A **Profile contact conversation** belongs to one **Profile contact**; Navivox must not show another Profile contact's scoped transcript items in the active **Transcript surface**.
- The **Transcript surface** renders the active **Profile contact** conversation, keeps tool activity distinct from ordinary assistant text, and owns composer/action-sheet behavior.
- A **Local command** uses the **Command word** and produces a local intent for Navivox to execute.
- The **Transcript surface** emits **Operator intents** upward instead of owning Gormes gateway calls or route changes.
- Setup and pairing surfaces emit **Pairing intents** upward instead of treating handoff submission, import, retry, or confirmation as generic form callbacks.
- A **Voice profile** belongs to a **Profile contact** and supplies gateway-owned STT/TTS/fallback configuration for future **Voice runs**.
- Voice credentials inside a **Voice profile** are write-only config inputs and should not appear as **Run record** evidence.
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

- "Hermes app" can imply replacing every preserved **Gormes gateway** surface. Resolved: use **Hermes endpoint**/**Hermes session** for new mainline runtime work, keep **Gormes gateway** terms only for preserved legacy paths, and use **Hermes Desktop reference** only for borrowed app-shape ideas.
- "profile", "agent", and "contact" can drift together. Resolved: use **Profile contact** for the `server_id + profile_id` chat-list identity; use agent only for server-owned runtime behavior.
- "wake word" can imply always-listening audio. Resolved: use **Command word** for the local prefix active only in Navivox text or voice command mode.
- "message list" can imply a passive log. Resolved: use **Transcript surface** for the active chat UI area because it renders tool activity, safety notices, approval prompts, and voice transcript bubbles as product state.
- "voice profile" can be confused with local microphone state or a single **Voice run**. Resolved: use **Voice profile** for per-Profile contact gateway STT/TTS/fallback config and write-only voice credentials.
- "voice message" can imply a single rendered bubble. Resolved: use **Voice run** for the full lifecycle and reserve voice bubble wording for Transcript surface rendering.
- "mic enabled", "STT flag", and "voice status" each describe only part of the gate. Resolved: use **Voice readiness** for the combined operator-visible ability to start a **Voice run** now.
- "voice run record" blurs local lifecycle state with gateway evidence. Resolved: use **Voice run** for the Navivox voice lifecycle and **Run record** for a redacted gateway evidence snapshot.
- "message id" can mean a display row identity rather than gateway evidence identity. Resolved: **Run record** inspection requires a Gormes-supplied **Run record reference**, not arbitrary transcript row ids.
- "run id", "session id", and "request id" can describe storage details behind evidence lookup. Resolved: use **Run record reference** at the Navivox product boundary.
- "login", "QR flow", and "connect-info flow" can imply separate setup products. Resolved: use **Pairing handoff** for the first-run transfer of Gormes gateway connection details, with direct Android link as the preferred path and QR/shared text/manual entry as fallbacks. Receiving fields is not completion; successful connection is completion.
- "setup status" can hide whether Navivox is waiting for details, reviewing an imported handoff, connecting, connected session-only, or failed retryably. Resolved: use **Pairing readiness** for the operator-visible setup state.
- "submit callback", "connect handler", and "retry button" can hide setup safety decisions. Resolved: use **Pairing intent** for operator setup actions that submit, import, retry, confirm, or reject Pairing handoffs.
- "server" can mean the **Gormes gateway** or the `server_id` half of a **Profile contact**. Resolved: use **Gateway identity** for recognizing a Gormes gateway; keep Profile contact `server_id` scoped to profile/contact routing.
- "server status" can imply raw transport health, auth, exposure, or durable identity. Resolved: use **Gateway status** for the operator-visible safe summary, and clearly mark unreported connection metadata instead of guessing it.
- "profile template" and "seed prompt" can imply local Navivox config generation. Resolved: use **Profile seed** for a natural-language request that the Gormes gateway drafts, with operator-confirmed workspace roots.
- "settings" can imply local Navivox preferences, Gormes config, profile config, gateway auth, or durable reconnect. Resolved: use **Local settings** for Navivox-install-scoped preferences, and route Gormes-owned changes to config/profile/gateway surfaces.
- "saved session" can imply stored authentication. Resolved: use **Known gateway metadata** for non-secret saved base URL/WebSocket/Gateway identity details, and reserve **Durable reconnect credential** for silent reconnect authorization.
- "No config available" can mean unsupported config-admin, failed schema loading, missing active scope, or genuinely empty config. Resolved: use **Config readiness** for the operator-visible availability/blocker state, and keep **Voice profile** availability separate.
- "Goncho degraded" can hide whether memory is unsupported, temporarily unavailable, empty, or scoped to the wrong **Profile contact**. Resolved: use **Memory readiness** for the operator-visible availability/blocker state, and reserve raw database health for gateway-owned evidence.
