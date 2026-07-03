# Navivox Architecture

Status: historical Gormes architecture plus active Hermes-first addendum
Updated: 2026-07-03

Current mainline has two runtime surfaces:

- Active Hermes companion path: native `HermesChannel`/`HermesApiChannel` over
  Hermes Agent HTTP/SSE API, rendered by `/hermes` (`lib/core/hermes/channel/hermes_api_channel.dart:19`,
  `lib/features/hermes_chat/screens/hermes_chat_screen.dart:42`).
- Preserved legacy Gormes path: `GatewayNavivoxChannel` and the existing
  Gormes `/v1/navivox/*` routes remain for historical/legacy operation.

The diagrams and detailed sections below were originally written for the
Gormes-first architecture. Treat them as legacy unless a section explicitly
mentions Hermes.

## 1. High-Level Architecture

### 1.1 Active Hermes-first path

```text
+----------------------------------------------------------------+
| Flutter Navivox app                                            |
|                                                                |
|  /hermes -> HermesChatScreen                                   |
|       |                                                        |
|       v                                                        |
|  HermesChannel / HermesApiChannel                              |
|       |                                                        |
|       v                                                        |
|  HermesApiClient + HermesTransportPolicy + SSE decoder         |
+-------+--------------------------------------------------------+
        |
        | HTTP JSON + SSE streams
        v
+----------------------------------------------------------------+
| Hermes Agent API server                                        |
|                                                                |
|  /health, /health/detailed, /v1/capabilities                   |
|  /api/sessions, /api/sessions/{id}/messages                    |
|  /api/sessions/{id}/chat(/stream), /api/sessions/{id}/fork     |
|  /v1/runs, /v1/runs/{id}/events, /approval, /stop              |
+----------------------------------------------------------------+
```

The Hermes path is native, not a compatibility adapter into the old Gormes
`NavivoxChannel` shape. Deferred/read-only surface honesty is centralized in
`hermesSurfaceReadiness()` (`lib/core/hermes/policy/hermes_surface_readiness.dart:27`),
and bounded diagnostics intentionally exclude secrets/raw payloads
(`lib/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart:10`).
Voice remains local device STT -> Hermes text turn; Hermes realtime/server audio
is not wired.

### 1.2 Preserved legacy Gormes path

```text
+---------------------------------------------------------------+
| Flutter Navivox app                                           |
|                                                               |
|  SetupScreen  ChatScreen  AgentsScreen  ConfigScreen  Voice   |
|       |           |            |             |           |     |
|       +-----------+------------+-------------+-----------+     |
|                           Riverpod state                      |
|                                 |                             |
|                       GatewayNavivoxChannel                   |
|                                 |                             |
|                       NavivoxGatewayClient                    |
+---------------------------------+-----------------------------+
                                  |
                                  | HTTP JSON + WebSocket JSON
                                  v
+---------------------------------------------------------------+
| Gormes Navivox channel                                        |
|                                                               |
|  /healthz                                                     |
|  /v1/navivox/status                                           |
|  /v1/navivox/sessions                                         |
|  /v1/navivox/turn                                             |
|  /v1/navivox/stream                                           |
|                                                               |
|  Auth, CORS, exposure validation, sessions, gateway fanout     |
+---------------------------------+-----------------------------+
                                  |
                                  v
+---------------------------------------------------------------+
| Gormes gateway manager and agent runtime                      |
+---------------------------------------------------------------+
```

The app is a first-party operator client. The server owns runtime behavior;
Flutter owns interaction, rendering, and local recovery state.

## 2. Current Package Layout

```text
lib/
  app.dart
  main.dart
  core/
    channel/                         # preserved legacy Gormes channel
      contracts/navivox_channel.dart
      gateway/gateway_navivox_channel.dart
      providers/navivox_channel_provider.dart
    gateway/                         # preserved legacy Gormes client/protocol
      client/
      capabilities/
      events/
      runtime/
    hermes/                          # active Hermes Agent API client/channel
      channel/hermes_api_channel.dart
      channel/hermes_channel.dart
      channel/hermes_channel_state.dart
      client/hermes_api_client.dart
      client/platform/
      models/
      policy/hermes_surface_readiness.dart
      policy/hermes_transport_policy.dart
      setup/secure_hermes_endpoint_store.dart
      sse/hermes_sse_event_decoder.dart
    protocol/
      navivox_event.dart
  features/
    agents/
      agents_screen_presentation.dart
      screens/agents_screen.dart
    chat/
      approval_banner_presentation.dart
      chat_screen_presentation.dart
      forward_message_intent.dart
      local_command_dispatcher.dart
      local_command_intent.dart
      transcript_composer_presentation.dart
      transcript_message_action_presentation.dart
      transcript_message_plain_text_presentation.dart
      transcript_safety_notice_presentation.dart
      transcript_text_message_presentation.dart
      transcript_thread_presentation.dart
      transcript_tool_call_presentation.dart
      transcript_voice_capture_flow.dart
      transcript_voice_message_presentation.dart
      voice_run_controller.dart
      screens/chat_screen.dart
      widgets/approval_banner.dart
      widgets/transcript_bubble.dart
      widgets/transcript_composer.dart
      widgets/transcript_input_panel.dart
      widgets/transcript_message_action_sheet.dart
      widgets/transcript_surface_frame.dart
      widgets/transcript_thread.dart
    config/
      config_apply_dispatcher.dart
      config_apply_flow_model.dart
      config_apply_presentation.dart
      config_draft_session.dart
      config_field_presentation.dart
      config_form_model.dart
      config_screen_presentation.dart
      config_section_presentation.dart
      screens/config_screen.dart
    hermes_chat/                    # active Hermes endpoint/session UI
      controllers/hermes_voice_run_controller.dart
      diagnostics/hermes_diagnostics_export.dart
      providers/hermes_channel_provider.dart
      screens/hermes_chat_screen.dart
    memory/
      memory_dashboard_presentation.dart
      screens/memory_dashboard_screen.dart
    profile_contacts/
      profile_contact_avatar.dart
      profile_contact_list_presentation.dart
      profile_contact_presentation.dart
    servers/
      gateway_connection_presentation.dart
      register_gateway_presentation.dart
      setup_guide_presentation.dart
      setup_qr_import_presentation.dart
      setup_screen_presentation.dart
      servers_screen_presentation.dart
      screens/setup_screen.dart
      screens/servers_screen.dart
    settings/
      settings_screen_presentation.dart
      providers/voice_settings_provider.dart
      screens/settings_screen.dart
    voice/
      services/audio_recorder.dart
      services/record_voice_capture_service.dart
      services/speech_recognizer.dart
      services/voice_capture_service.dart
      widgets/voice_morph_surface.dart
  router/
    providers/app_router.dart
    routes/app_routes.dart
  shared/
    widgets/app_shell.dart
    widgets/app_shell_presentation.dart
```

Near-term additions should follow the same feature-first shape. New Hermes work
belongs under `core/hermes/` and `features/hermes_chat/`; preserved Gormes work
stays under the legacy gateway/channel/features modules.

## 3. Core Responsibilities

### 3.0 Route locations

`AppRoutes` owns route path constants, generated route locations, and local route
recognizers:

- `chatLocation(serverId, profileId)` builds encoded Profile contact chat paths
  for `server_id + profile_id` identities.
- `configSectionLocation(sectionId)` builds encoded config section paths.
- `isSetupLocation(location)` and `isChatThreadLocation(location)` centralize
  local route prefix checks used by the router and app shell.

Screens, Operator intents, and dispatchers should not concatenate `/chats/...`
paths directly. This keeps Profile contact route encoding local to one Module
and prevents slashes or spaces in Gormes gateway/profile ids from becoming route
segments.

### 3.0.1 App shell presentation

`AppShellPresentation` owns app shell navigation presentation:

- Ordered destination routes, labels, and icons for Chats, Gateways, Profiles,
  Memory, Config, and Settings.
- Drawer header title/subtitle and the mobile navigation menu tooltip.
- Per-location shell state, including selected destination fallback and whether
  the mobile navigation menu is hidden on Profile contact chat threads.

`AppShell` keeps Flutter layout, Material drawer/rail rendering, theme lookups,
`Scaffold` placement, and `GoRouter` navigation side effects.

### 3.1 Hermes API client and channel

`HermesApiConfig` and `HermesApiClient` own Hermes Agent API URL derivation and
HTTP/SSE calls:

- `/health`, `/health/detailed`, and `/v1/capabilities` for readiness and
  transport gating.
- `/api/sessions`, `/api/sessions/{id}/messages`, session chat streaming,
  session rename/delete/fork, and read-only jobs/catalog calls.
- `/v1/runs`, run events, approval response, and stop when capability-gated.

`HermesApiChannel` adapts those calls into `HermesChannelState` for
`HermesChatScreen`, including active session, messages, voice runs, approvals,
detailed health, catalogs, jobs, and bounded error state. API keys are stored
through the Hermes endpoint store, not routes or diagnostics.

### 3.2 Legacy Gateway Client

`NavivoxGatewayConfig` owns URL derivation:

- `healthUri` -> `/healthz`
- `statusUri` -> `/v1/navivox/status`
- `sessionsUri` -> `/v1/navivox/sessions`
- `turnUri` -> `/v1/navivox/turn`
- `streamUri` -> `/v1/navivox/stream` with `http` mapped to `ws` and `https`
  mapped to `wss`

It also owns bearer auth header creation. Bootstrap tokens remain in memory, while
issued durable device credentials are written through
`SecureStorageDurableCredentialStore`/platform durable key stores rather than
`shared_preferences`; secrets are never embedded in route paths or diagnostics.

### 3.3 Legacy Gateway Channel

`GatewayNavivoxChannel` adapts gateway events into UI state:

- Connects after a successful status probe.
- Opens the WebSocket stream.
- Sends `start_turn` messages.
- Tracks the active session.
- Appends user, assistant, system, and tool messages.
- Converts `tool_call_started` and `tool_call_finished` into structured tool
  message state.

### 3.3 Server Channel

`internal/channels/navivox.Channel` exposes:

- `Handler(inbox)` for HTTP tests and gateway mounting.
- `Run(ctx, inbox)` for serving the configured channel.
- Gateway `Send`, `SendPlaceholder`, `EditMessage`, and `EditMessageFinal`
  methods for assistant output fanout.

The server validates Navivox config at startup and fails closed when exposure or
auth settings are unsafe.

## 4. Connection Lifecycle

```text
Operator runs gormes navivox connect-info
        |
        v
Flutter receives base URL and optional token
        |
        v
GET /healthz
        |
        v
GET /v1/navivox/status
        |
        v
Open WS /v1/navivox/stream
        |
        v
Create local server entry and navigate to chat
        |
        v
Send start_turn over stream or POST /v1/navivox/turn
        |
        v
Gormes gateway processes the turn
        |
        v
assistant_delta / assistant_message / tool_call_* / done
```

Reconnect behavior:

- The client uses bounded exponential backoff.
- UI keeps existing messages visible while reconnecting.
- A lost stream is visible as connection state, not as deleted chat history.

## 5. HTTP Turn Flow

`POST /v1/navivox/turn` accepts:

```json
{
  "request_id": "client-generated-id",
  "session_id": "optional-existing-session",
  "text": "hello",
  "metadata": {
    "client": "navivox",
    "platform": "flutter"
  }
}
```

Successful response:

```json
{
  "request_id": "client-generated-id",
  "session_id": "navivox-session-id",
  "status": "queued"
}
```

The WebSocket path uses the same message semantics for `start_turn`.

## 6. Event Model

Server events are JSON objects:

```json
{
  "type": "assistant_delta",
  "request_id": "client-generated-id",
  "session_id": "navivox-session-id",
  "text": "partial text"
}
```

Known event types:

- `pong`
- `session_started`
- `assistant_delta`
- `assistant_message`
- `tool_call_started`
- `tool_call_finished`
- `error`
- `done`

Unknown events are ignored until the app has a renderer for them.

## 7. Chat And Tool Rendering

The chat layer receives typed channel state, not wire payloads.

Message kinds:

- User text.
- Assistant text.
- System status.
- Tool call card.
- Voice message bubble.

Tool cards own:

- tool name
- tool call id
- status
- summary
- artifacts
- approval state
- redacted details

This keeps tool output inspectable without turning the transcript into a log
dump.

Transcript thread presentation:

- `TranscriptThreadPresentation` owns pure Transcript surface thread display
  state: empty-state title, message row order, user/assistant row role,
  bubble-tail grouping, active-stream pause eligibility, typing indicator label,
  and list item count.
- `TranscriptThread` keeps `ListView`, `ScrollController`, empty-state icon,
  typing indicator Material layout, `TranscriptBubble` composition, and callback
  wiring for Operator intents.
- This keeps sequencing and active-stream row policy testable through a pure
  Module Interface while preserving widget Adapters as rendering-only seams.

Voice message presentation:

- `TranscriptVoiceMessagePresentation` owns pure Voice run bubble display state
  for the Transcript surface: title, duration label, transcript text,
  transcript visibility, and confidence-to-morph-intensity handoff.
- `TranscriptBubble` keeps `VoiceMorphSurface`, row/column layout, text styles,
  truncation, and kind-specific widget composition.
- This keeps Voice run bubble wording and optional transcript policy testable
  through a pure Module Interface while preserving the widget Adapter as the
  rendering seam.

Text message presentation:

- `TranscriptTextMessagePresentation` owns pure text-message display and intent
  text for the Transcript surface: exact operator text, null-to-empty fallback,
  and has-text state.
- `TranscriptBubble`, `TranscriptMessageActionPresentation`, and
  `ForwardMessageIntent` all consume this Module so rendering, copy/TTS actions,
  and forward Operator intent share the same text fallback policy.
- Widget rendering, clipboard/TTS effects, channel sends, and route side effects
  remain in their Adapters.

Message plain-text presentation:

- `TranscriptMessagePlainTextPresentation` owns the non-visual plain-text
  projection for any Transcript surface message kind.
- It centralizes copy/TTS/forward text for ordinary text, Voice run transcripts,
  tool cards, safety warnings, and approval requests behind one pure Module
  Interface: `text` plus `hasText`.
- `TranscriptMessageActionPresentation` and `ForwardMessageIntent` consume this
  Module so message actions and forward Operator intents cannot drift on
  newline joining or empty-line omission rules.

TranscriptBubble adapter-local seams:

- `TranscriptBubble` intentionally keeps bubble shell layout, tail painting,
  width/radius math, timestamp placement, Material color mapping, and the
  `_MessageBody` widget dispatcher as Adapter-local Implementation details.
- The deletion test is weak for a separate bubble-shell Module today: deleting
  that hypothetical Module would move Flutter layout constants back into one
  Adapter, not spread Transcript surface policy across multiple callers.
- The message-kind dispatcher is also Adapter-local because it selects concrete
  Flutter widgets while kind-specific policy already lives in pure Module
  Interfaces (`TranscriptTextMessagePresentation`,
  `TranscriptVoiceMessagePresentation`, `TranscriptToolCallPresentation`,
  `TranscriptSafetyNoticePresentation`, and
  `TranscriptMessagePlainTextPresentation`).
- Revisit this only when a second Adapter needs the same bubble shell policy or
  a new message kind creates duplicated non-visual rules outside the existing
  pure Modules.

Tool call presentation:

- `TranscriptToolCallPresentation` owns pure tool card display state for the
  Transcript surface: tool name, status label, status tone, summary visibility,
  and artifact row descriptors.
- `TranscriptBubble` keeps Material layout, tool/attachment icon choices,
  status-tone color mapping, and message action side effects.
- This keeps tool output policy testable through a pure Module Interface while
  preserving widget Adapters as rendering-only seams.

Safety notice presentation:

- `TranscriptSafetyNoticePresentation` owns pure safety/approval card display
  state for the Transcript surface: notice tone, card key identity, title,
  message, severity visibility, and risk visibility.
- `TranscriptBubble` keeps Material layout, warning/approval icon choices,
  theme color mapping, and message action side effects.
- This keeps safety notice wording and optional row policy testable through a
  pure Module Interface while preserving the widget Adapter as the rendering
  seam.

Approval prompt presentation:

- `ApprovalBannerPresentation` owns approval prompt title, prompt copy passthrough,
  Allow/Deny button labels, canonical risk labels, risk-badge visibility, and
  high-risk warning visibility.
- `ApprovalBanner` keeps the `approvalRequests` subscription, Material layout,
  warning icon choice, `respondToApproval` side effects, and pending-banner
  lifecycle.
- This keeps safety/risk wording local to a pure Module Interface while keeping
  channel resolution side effects in the Adapter.

Profiles route presentation:

- `AgentsScreenPresentation` owns the screen-level presentation choice between
  the legacy agent list, the Profile contact fallback list, and the empty
  Profile contact state.
- It owns Profiles screen chrome, refresh copy, Profile contact fallback heading
  copy, empty-state copy, and create/import unavailable sheet copy.
- It reuses `ProfileContactListPresentation` for active Gormes gateway
  filtering and sorted fallback Profile contacts instead of reimplementing list
  rules in the `AgentsScreen` Adapter.
- `AgentsScreen` keeps icons, card/list layout, channel side effects, selected
  legacy-agent dispatch, selected Profile contact dispatch, refresh, and
  create/import unavailable-sheet launch behavior.

Profile contact avatar:

- `ProfileContactAvatar` owns shared Profile contact identity avatar rendering
  for the chat list, Profiles fallback, and gateway management sheet.
- `ProfileContactPresentation` supplies the safe avatar initial, stable color
  index, and screen-reader label so widget Adapters do not repeat
  `displayName.characters.first` or diverge on seeded color rules.
- Blank display names fall back to Profile contact identity data before showing
  a generic avatar label.

Profile contact presentation:

- `ProfileContactPresentation` owns shared Profile contact copy for list rows,
  search terms, detail-sheet diagnostics, identity/channel/memory/config/log
  sections, scoped detail actions, and Profiles fallback summary lines.
- `ProfileContactsScreenPresentation` owns the Profile contacts screen chrome,
  search hints/tooltips, empty-state copy, server-filter all label, and
  add-profile sheet row copy.
- `ProfileContactsScreen` and `AgentsScreen` keep icons, row/card layout,
  modal sheets, navigation, text-controller lifecycle, and channel side effects
  instead of rebuilding Profile contact copy inline.
- This preserves different Profile contact row layouts while centralizing the
  product words and diagnostics behind one pure Module Interface.

Profile contact list presentation:

- `ProfileContactListPresentation` owns sorted and filtered Profile contact list
  state for the chat list.
- It centralizes display-name sorting, selected Gormes gateway filtering,
  search through `ProfileContactPresentation.searchTerms`, empty/visible state,
  server-filter visibility, and visible-count copy.
- `ProfileContactsScreen` keeps text controller lifecycle, selected server
  filter state, route changes, modal sheets, and concrete Profile contact
  selection side effects.

Memory dashboard presentation:

- `MemoryDashboardPresentation` owns memory dashboard copy and local display
  state for Goncho memory overview, search results, detail sheets, and safe
  management actions.
- It centralizes active-scope fallback labels, overview count ordering, database
  and timestamp lines, search empty/degraded copy, memory item metadata lines,
  detail row ordering, correction-dialog copy, and action-result snackbar
  fallback copy.
- `MemoryDashboardScreen` keeps Riverpod loading, Gormes gateway memory calls,
  search field state, modal sheets, SnackBars, and Material rendering side
  effects.

Settings screen presentation:

- `SettingsScreenPresentation` owns voice-settings screen copy and local display
  state for management links, registered gateway/Profile contact summaries,
  active Gormes gateway trust state, and current-session scope rows.
- It centralizes management row routes/copy, count pluralization, active gateway
  and active Profile contact subtitle formatting, and Profile contact health
  labels.
- `SettingsScreen` keeps Riverpod voice-settings state, switch callbacks,
  `GoRouter` navigation, icon choices, and Material rendering side effects.

Gateways route presentation:

- `ServersScreenPresentation` owns Gormes gateway row assembly for the Gateways
  tab.
- It centralizes gateway sorting, Profile contact grouping by server id,
  active/registered gateway subtitle copy, count-chip labels, active Profile
  contact copy, compact Profile contact health labels, manage-gateway sheet
  labels, empty Profile contact copy, disconnect confirmation copy, and
  disconnect result snackbar copy.
- `ServersScreen` keeps Flutter rendering, register/test connection form state,
  manage-gateway modal sheets, disconnect dialogs, snackbars, Navigator calls,
  and channel side effects.

Gateway connection presentation:

- `GatewayConnectionPresentation` owns shared manually-entered Gormes gateway
  connection input rules.
- It centralizes supported URL scheme validation plus trimmed base URL/token
  payload construction with blank-token omission.
- `SetupScreen` and `RegisterGatewayPresentation` both use this Module so
  first-run setup and in-session gateway registration accept the same URL
  schemes and build the same channel connect payload shape.

Setup guide presentation:

- `SetupGuidePresentation` owns the Termux setup guide copy shown on the
  first-run setup screen.
- It centralizes the guide intro, ordered copy actions, clipboard payloads,
  copy-success messages, copy-failure messages, and token-safety invariants.
- `SetupScreen` keeps Flutter layout, icons, `Clipboard` side effects,
  connection state, QR image import, and routing while rendering/copying setup
  guide entries through one Adapter path.

Setup QR import presentation:

- `SetupQrImportPresentation` owns setup QR/import payload parsing for the
  first-run setup screen.
- It centralizes `navivox://connect` URI parsing, connect-info JSON fallback,
  free-text URL/token extraction, websocket-to-REST base URL derivation, and
  setup import result shape.
- Canonical `navivox://connect` descriptors delegate to
  `NavivoxPairingDescriptor`, whose core parser now derives `baseUri` from a
  websocket-only pairing descriptor when `base_url` is absent.
- `SetupScreen` keeps image picker and QR scanner side effects, field mutation,
  and platform-specific import exceptions.

Setup screen presentation:

- `SetupScreenPresentation` owns first-run setup screen copy and notice rules.
- It centralizes connection field labels/semantics, QR import status notices,
  validation notices, connect failure recovery guidance, and token-safe fallback
  behavior for error details.
- `SetupScreen` keeps Flutter layout, image picker and QR scanner side effects,
  text controller mutation, Clipboard side effects, `channel.connect`, and
  routing.

Register gateway presentation:

- `RegisterGatewayPresentation` owns the pure Gormes gateway registration form
  rules used by the Gateways tab.
- It centralizes field labels/help text, connect-info instructions, testing
  button copy, and connection result snackbar copy while delegating shared URL
  validation and payload construction to `GatewayConnectionPresentation`.
- `_RegisterGatewaySheet` keeps `TextEditingController` lifecycle, form
  validation trigger, progress state, modal rendering, and `channel.connect`
  side effects.

Local commands:

- `LocalCommandResolver` owns Command word parsing, command-mode voice fallback,
  built-in Local command classification, Profile contact matching,
  disambiguation copy, disabled-switching copy, and unknown-command copy.
- `LocalCommandDispatcher` owns resolved Local command execution decisions:
  Gormes turn cancel/stop channel calls, Profile contact selection, settings and
  Profile contact route locations, snackbar/notice copy, and pending Voice run
  cancellation signals.
- `ChatScreen` keeps widget-only side effects: command-mode timer state,
  `VoiceRunController` pending cancellation, `GoRouter` navigation, and
  `ScaffoldMessenger` snackbars.
- Local commands are never sent to the Gormes gateway as chat text.

Chat screen presentation:

- `ChatScreenPresentation` converts `NavivoxChannelState`, Voice settings,
  local voice availability, and runtime voice errors into screen-level copy and
  Transcript surface inputs.
- It owns app bar title/subtitle copy, chat info title/tooltip/rows, pending
  Voice run bubbles, assistant typing copy, forward targets, and continuous
  voice recovery copy.
- `VoiceModePresentation` owns continuous-voice banner labels, control-sheet
  title/status/subtitle, typed control rows, STT diagnostic row copy, command
  word/how-it-works copy, and local trust/cancel/settings action labels.
- `ChatScreen` keeps side effects: routing, channel calls, snackbars, capture
  callbacks, Voice run timers, modal rendering, row icon choices, trust setting
  writes, and Local command execution.

Forward message Operator intent:

- `ForwardMessageIntent` owns forwarding a Transcript surface message to another
  Profile contact.
- It centralizes forward text extraction for text, voice, tool, safety, and
  approval messages, target Profile contact selection, Gormes turn submission,
  destination chat route construction, and snackbar copy.
- `ChatScreen` keeps UI adapters only: `GoRouter` navigation and
  `ScaffoldMessenger` snackbars.

Transcript message action presentation:

- `TranscriptMessageActionPresentation` owns message action-sheet copy for the
  active Transcript surface Adapter.
- It centralizes action text extraction for text, voice, tool, safety, and
  approval messages, copy/read-aloud/pause labels, TTS unavailable copy, and
  forward target row labels.

Transcript message action sheet:

- `TranscriptMessageActionSheet` owns the shared action-sheet rendering for the
  active Transcript surface Adapter.
- It renders title, selectable action text, pause/copy/read-aloud rows, TTS
  unavailable recovery, and Profile contact forward target rows from
  `TranscriptMessageActionPresentation`.

Transcript widget retirement hygiene:

- Retired private `widgets/src` Transcript fragments are removed from the active
  tree instead of kept as comment-only tombstones.
- Active Transcript widget Modules live directly under `features/chat/widgets/`
  so agents and maintainers navigate to executable Interfaces, not stale
  fragments.

Transcript bubble rendering:

- `TranscriptBubble` owns shared bubble geometry for the active Transcript
  surface Adapter.
- It centralizes user/assistant alignment, tail painting, timestamp placement,
  text/tool/voice/safety/approval message body rendering, and message action
  sheet launch.
- The thread Module supplies message-list context, including tail grouping,
  typing state, and injected Operator intent callbacks for pause and forward.

Transcript thread rendering:

- `TranscriptThread` owns shared thread rendering for `TranscriptSurfaceFrame`.
- It centralizes the empty Transcript surface state, scrollable message list,
  user/assistant tail grouping, assistant typing indicator, bubble construction,
  Profile contact forward targets, TTS injection, and active-turn pause
  availability.
- `TranscriptSurfaceFrame` keeps controller lifecycles and auto-scroll triggers;
  adapters provide concrete Operator intent callbacks.

Transcript surface frame:

- `TranscriptSurfaceFrame` owns the stateful Transcript surface frame behind
  the active `TranscriptSurface` Adapter.
- It centralizes text controller lifecycle, scroll controller lifecycle,
  initial auto-scroll, appended-message auto-scroll, thread placement, input
  panel placement, and shared wiring between thread/input Modules.
- `TranscriptSurface` keeps the public Adapter Interface, active-screen-only
  hooks, route side effects, and concrete Operator intent callbacks.

Transcript input panel:

- `TranscriptInputPanel` owns shared composer-adjacent input behavior for the
  active Transcript surface Adapter.
- It centralizes text send-and-clear behavior, capture/stop state, local capture
  error rendering, `TranscriptVoiceCaptureFlow` execution, Voice run start/fail
  hook dispatch, captured-voice Operator intent dispatch, and composer SafeArea
  placement.
- `TranscriptSurfaceFrame` keeps controller lifecycles, thread placement,
  auto-scroll, and input placement; the `TranscriptSurface` Adapter provides
  route side effects and concrete send/voice Operator intent callbacks.

Transcript composer rendering:

- `TranscriptComposer` owns shared composer rendering for `TranscriptInputPanel`.
- It centralizes text entry, send button wiring, quick emoji insertion, share
  sheet rendering, voice unavailable recovery sheet rendering, voice settings
  launch, and capture/stop button states.
- `TranscriptInputPanel` keeps capture flow execution and text send clearing;
  the `TranscriptSurface` Adapter provides the concrete Operator intents.

Transcript composer presentation:

- `TranscriptComposerPresentation` owns composer copy shared by
  `TranscriptComposer` callers.
- It centralizes voice unavailable canonicalization, voice button state,
  typed recovery-sheet rows, row action kinds, voice-settings subtitles, quick
  emoji, input hint copy, attach tooltip copy, share-sheet title, and
  share-sheet options.
- `TranscriptComposer` keeps modal rendering details, icon choices, Navigator
  side effects, controller updates, and send/attach/toggle Operator intent
  emission.

Transcript voice capture flow:

- `TranscriptVoiceCaptureFlow` runs a `VoiceCaptureService` with a timeout and
  returns a typed outcome: unavailable, captured, or failed.
- It centralizes timeout and generic failure copy for `TranscriptInputPanel`.
- `TranscriptInputPanel` keeps mounted checks, capture state, error rendering,
  `onVoiceCaptureStarted`, `onVoiceCaptureFailed`, and captured-voice Operator
  intent dispatch.

Voice run controller:

- `VoiceRunController` owns Chat screen Voice run lifecycle decisions after the
  Transcript surface reports capture callbacks.
- It centralizes pending Voice run id state, pending-send notice copy, runtime
  device-STT disable reasons, failure reason canonicalization, Local command
  capture cancellation, pending cancellation, and auto-send readiness checks.
- `ChatScreen` keeps widget-only side effects: timers, `setState`, routing,
  snackbars, and Local command dispatch.

## 8. Agent Seed Architecture

The seed flow is a server operation. Flutter submits a short phrase and renders
the returned draft:

```text
seed text
  -> server generator
  -> agent draft
  -> editable sections
  -> validate
  -> apply
```

Draft sections:

- Agent profile.
- Prompt/instructions.
- Tool access.
- Voice defaults.
- STT/TTS provider preferences.
- Safety/escalation policy.

No generated draft is applied without operator confirmation.

## 9. Config Admin Architecture

```text
schema + redacted values
  -> local form model
  -> diff request
  -> validation request
  -> confirmation
  -> apply request
  -> reload/reconnect result
```

Rules:

- Server schema controls fields, types, validation, and secret metadata.
- `ConfigFormModel` owns schema rows, sections, typed coercion, and redacted values.
- `ConfigFieldPresentation` owns field labels, display text, stable widget keys, input mode, validation copy, and secret-safe edit presentation.
- `ConfigSectionPresentation` owns section labels, descriptions, field presentation construction, validation lookup, and edit-state matching.
- `ConfigDraftSession` owns draft values, editing path transitions, staged edits, blank-secret clearing, and post-apply draft cleanup.
- `ConfigApplyFlowModel` owns pending draft changes, validation messages, restart markers, confirmation flags, and apply payloads.
- `ConfigApplyPresentation` owns pending-card and confirmation-dialog operator copy, including apply labels, restart copy, validation copy, and change summaries.
- `ConfigApplyDispatcher` owns validated apply dispatch, including plain config writes, write-only secret writes, invalid-flow safety, and applied path reporting.
- `ConfigScreenPresentation` owns screen-level assembly from Gormes gateway channel state, including scope copy, empty/missing-section state, section presentations, apply flow, and apply presentation.
- Secret values are write-only.
- UI displays redacted status and source evidence.
- Changes that affect gateway exposure require explicit confirmation.

## 10. Voice Architecture

Current behavior can submit a device transcript as a text turn.

Planned voice flow:

```text
record audio
  -> local transcript when available
  -> Voice run lifecycle state
  -> server STT/profile
  -> agent turn
  -> server TTS/profile
  -> playback event
```

Voice runs let the UI show capture, transcript, provider, playback, and error
state as durable objects.

### 10.1 Client-local Voice run first

The first Voice run slice is client-local. Navivox records lifecycle metadata,
transcript source, pending-send/cancel/failure state, and planned STT/TTS
status while continuing to submit the final transcript through the existing
`start_turn` path.

Historical Gormes server voice events remain deferred. Planned event names were:

- `voice_run_started`
- `voice_transcript_partial`
- `voice_transcript_final`
- `voice_server_stt_complete`
- `voice_tts_ready`
- `voice_playback_started`
- `voice_playback_stopped`
- `voice_error`

These names are not active protocol until Gormes emits at least one of them.
Binary audio transport remains deferred until Voice run lifecycle,
retention/redaction policy, and a server STT/TTS event contract exist.
`RecordVoiceCaptureService` is a local/future-facing recorder path only unless
wired through that approved audio transport contract; the production voice
submission path remains transcript-first.

## 11. Router Architecture

Current router:

- Starts at `/chats`.
- Redirects to `/setup` when no gateway-backed server exists.
- Redirects away from `/setup` once a gateway-backed server exists.
- Mounts setup plus shell tabs for chat, servers, agents, and config.

Detail routes should be added only when their screens can work against the
current gateway contract.

## 12. Trust Boundaries

Sensitive data handling:

| Data | Location | Policy |
|------|----------|--------|
| Bearer token | Memory or secure local storage | Redacted in UI/logs; never in routes. |
| Gateway base URL | Local app state | Safe to show. |
| Chat text | Local cache and server session | Redact when marked private. |
| Tool output | Server event and UI card | Redact sensitive fields by default. |
| Config secrets | Server only | Write-only from app. |
| Voice audio | Future voice run storage | Retention and redaction policy required before persistence. |

Exposure handling:

- Disabled by default.
- Loopback for local mode.
- VPN validation for VPN-class modes.
- Explicit confirmation for public exposure.
- Tokens are never printed by `connect-info`.

## 13. Platform Notes

| Area | Android | iOS | Linux | Windows | macOS |
|------|---------|-----|-------|---------|-------|
| HTTP/WebSocket client | Dart IO | Dart IO | Dart IO | Dart IO | Dart IO |
| Secure token storage | Platform secure storage | Keychain | Secret service | DPAPI | Keychain |
| Local unlock | Biometric/PIN | Biometric/PIN | App PIN fallback | Windows Hello/PIN | Touch ID/PIN |
| Voice capture | Platform mic | Platform mic | System mic deps | System mic | Platform mic |
| Local STT | Platform service | Platform service | Optional fallback | Optional fallback | Platform service |

Platform support should degrade to text-only chat when voice features are not
available.

## 14. Test Architecture

Unit tests:

- URL derivation and auth headers.
- Gateway event decode.
- Channel state transitions.
- Router redirects.
- Tool card state.
- Config form validation.

Integration tests:

- Fixture HTTP gateway for Flutter setup and chat.
- In-process Go handler for `/healthz`, status, turn, and stream.

Acceptance smoke:

- Operator can connect from `connect-info`, open chat, submit one turn, and see
  streamed assistant output without telephony setup.
