# Navivox UI Design Guide

Status: historical Gormes UI guide plus active Hermes-first addendum
Updated: 2026-07-03
Source: current Hermes `/hermes` UI, legacy HTTP/WebSocket gateway plan, PRD, and app shell

## 1. Design Principles

1. **Connect and talk first**: the active Hermes-first path is `/hermes` ->
   Hermes base URL/API key -> health/capabilities -> session chat. The preserved
   Gormes path remains base URL, token, health check, stream, chat.
2. **Work-focused, not marketing**: no landing page before the operator can talk
   to a Hermes session or preserved Gormes profile.
3. **Tool calls are first-class UI**: use structured cards, not transcript log
   dumps.
4. **Secrets are invisible by design**: write-only fields, redacted status, no
   read-back.
5. **Server-authoritative config**: the app edits drafts only where safe APIs
   exist. Hermes config admin remains deferred/read-only; preserved Gormes
   validates and applies legacy config changes.
6. **Voice is an input mode, not a setup blocker**: text turn fallback always
   works. Current Hermes voice is local device STT submitted as a text turn;
   Hermes realtime/server audio is not implemented.
7. **Trust boundaries stay visible**: connected host, auth mode, exposure mode,
   and token-required state are shown without leaking secrets.
8. **Dense, adaptive layout**: mobile keeps chat immersive with a
   Telegram-style bottom navigation pill for primary top-level destinations,
   plus a small `More` sheet for overflow destinations; desktop uses a left
   rail and status bar.
9. **Telegram-inspired, Gormes-owned**: borrow fast scanning, grouped bubbles,
   status ticks, action sheets, and compact navigation from Telegram-like apps,
   but keep Navivox focused on Gormes profiles, tools, voice transcripts, and
   safe config.
10. **Profiles are contacts**: the chat list represents `server + profile_id`
    contacts. A profile is an isolated Gormes home, not a live concurrent agent
    router.
11. **Local voice commands stay local**: the command word, calibration, aliases,
    pins, server trust, and voice switching are Navivox app settings; Gormes
    remains authoritative for profile/config/workspace state.

## 2. Primary Screens

### 2.1 Active Hermes Screen

`HermesChatScreen` is the fresh-install default route through `/hermes`
(`lib/router/providers/app_router.dart:22`, `lib/features/hermes_chat/screens/hermes_chat_screen.dart:42`).
It owns its own Hermes endpoint setup form and is not gated by legacy Gormes
server state.

Active Hermes UI elements:

- Setup presets for local host, Android emulator, and remote/LAN Hermes URLs.
- Base URL plus optional API key entry; keys must not appear in routes,
  screenshots, diagnostics, or transcripts.
- Capability/health strip with safe summaries only.
- Sessions panel with list/select/new plus capability/API-gated rename, fork,
  and delete actions.
- Composer, push-to-talk, and continuous voice; voice submits local STT
  transcripts as Hermes text turns.
- Approval, stop, tool-progress, read-only catalog/jobs, and bounded diagnostics
  surfaces when advertised.
- Saved endpoint profile chips for multi-endpoint/profile management, with API
  keys kept in secure storage.
- Deferred/read-only labels for server realtime audio, config admin, memory UI,
  jobs admin, messaging gateways, persona/SOUL, attachments/media, files/context
  folders, and raw diagnostics/log export via `hermesSurfaceReadiness()`
  (`lib/core/hermes/policy/hermes_surface_readiness.dart:27`).

### 2.2 Launch Routing

- Fresh install or no saved legacy Gormes server: open `/hermes`.
- Legacy Gormes setup explicitly requested: open `/setup`.
- One healthy saved legacy Gormes server and usable profile: open that profile
  chat.
- Multiple legacy servers, offline/auth issue, or pending attention: open the
  profile contact list.

### 2.2 Profile Contact List

```text
+------------------------------------------------+
| [N] Navivox                         [search][⋮]|
+------------------------------------------------+
| Search Profiles                                |
+------------------------------------------------+
| M  Mineru Builder                         9:41 |
|    Ready to work · online · 2 roots        mic |
| W  Work Profile                          9:22 |
|    Waiting for token · auth required       !   |
| P  Personal                               Tue |
|    Gateway unavailable · offline          !   |
+------------------------------------------------+
| Chats        Profiles      Memory       More  |
+------------------------------------------------+
```

Chat list rows are profile contacts:

- Stable identity: `server_id + profile_id`.
- Deterministic Telegram-like gradient avatar from `server_id + profile_id`.
- Server label stays searchable and appears in details/menus, not as a row chip.
- Server-authoritative display name, with canonical profile id in details.
- One-line sanitized preview combines latest message, health, and compact
  workspace status.
- Timestamp is right-aligned with the title baseline.
- Health/provider/model/memory/gateway/WS state collapses into preview copy or
  detail sheets instead of row chips.
- Attention count for approvals, failed tools, auth, offline server, workspace
  issues, or active/stuck turns appears as a small right-side status marker.
- Compact workspace summary such as `2 roots` or `workspace issue`, never raw
  paths.
- Row tap opens the current/latest session for the profile.
- Row mic opens continuous voice when the server is trusted and healthy.
- Long press opens profile details/edit.
- Floating add button opens an action sheet with plugged actions for New
  profile/Create from seed and Add server.
- Overflow menu routes to gateway, profile, memory, config, and settings
  screens.

The list is flat by default. Pinned contacts sort first locally, but pins never
change command routing.

### 2.3 Setup Screen

```text
+------------------------------------------------+
| Connect to Gormes                              |
+------------------------------------------------+
| Paste connect-info                             |
| [ http://127.0.0.1:8765                  ]     |
|                                                |
| Token                                          |
| [ ************************************** ]     |
|                                                |
| healthz     not checked                        |
| status      not checked                        |
| stream      not connected                      |
|                                                |
| [Connect and talk]                             |
+------------------------------------------------+
| gormes navivox connect-info                    |
+------------------------------------------------+
```

States:

- Empty: show the host command and base URL field.
- Health failed: show gateway unavailable and retry.
- Unauthorized: show token/auth action.
- Exposure blocked: show server-side exposure guidance.
- Connected: navigate to chat.

### 2.4 Chat Screen

```text
+------------------------------------------------+
| < Mineru Builder             local-gormes  OK  |
+------------------------------------------------+
| Pinned: trusted local server, token redacted    |
|                                                |
| Today                                      v   |
|                                                |
|                         Check server status    |
|                                      9:41  sent |
|                                                |
| Mineru Builder                                 |
| Checking now...                                |
|                                                |
| +-- execute_command ------------------------+  |
| | Status: running                            |  |
| | Command: uptime                            |  |
| | [Expand]                                   |  |
| +---------------------------------------------+ |
|                                                |
| Mineru Builder                                 |
| Server is healthy.                             |
+------------------------------------------------+
| [+]  Message Navivox...              [mic]  >  |
+------------------------------------------------+
```

Key UI elements:

- Server label opens server switcher.
- Profile pill opens profile switcher.
- Status chip shows connected, reconnecting, offline, unauthorized, or blocked.
- User messages are right-aligned.
- Assistant messages are left-aligned.
- Streaming assistant text updates in place.
- `ToolCallCard` appears inline as a distinct execution card with status,
  approvals, and expandable details.
- Voice button starts continuous voice for the active profile when allowed.
- Long press opens a message action sheet: copy, retry, inspect event, reveal
  redacted fields when authorized.
- The plus button opens a plugged share sheet: Upload file and Photo/video
  explain upload readiness until Gormes exposes an upload endpoint, while
  Workspace file routes to Memory/workspace. Future attachment handlers attach
  through composer callbacks, not inert rows.
- Chat info exposes action rows for profile contacts, workspace/memory, profile
  config, Navivox settings, and gateway details.
- Profiles empty state uses the same plugged profile creation routes: Create from
  seed opens the profile seed flow, and Add gateway opens gateway registration.
- Gateway management sheets make profile rows actionable: selecting a profile
  scopes the channel and opens its chat.
- Composer text that exactly matches a command-word command, such as
  `navi mineru`, is handled locally by Navivox and is not sent to Gormes.

### 2.5 Continuous Voice

```text
+------------------------------------------------+
| Voice: Mineru Builder       local-gormes   OK  |
+------------------------------------------------+
| Listening                                      |
| Command word: Navi                             |
|                                                |
| user bubble: checking server status            |
| Sending...                               cancel |
|                                                |
| [command] [stop]                               |
+------------------------------------------------+
```

Command mode:

```text
+------------------------------------------------+
| Command mode                              0:05 |
+------------------------------------------------+
| Say a profile name, stop, cancel, settings,    |
| or help.                                       |
+------------------------------------------------+
```

Voice rules:

- Continuous voice is a global app mode with one active target profile.
- Row mic starts listening immediately after mic permission and per-server
  local trust exist.
- Device speech-to-text streams into the active profile as a voice-marked user
  bubble.
- Auto-send is the default, with a short visible `Sending...` grace window.
- The command word defaults to `navi` and can be changed locally.
- Optional calibration asks the user to say the command word three times; reset
  is available in Settings.
- Command word detection only works at the beginning of an utterance and only
  while Navivox voice mode is active.
- Saying the command word alone enters local command mode for about five
  seconds.
- Direct commands also work: `navi mineru`, `navi cancel`, `navi stop`,
  `navi settings`, `navi help`.
- Command-mode speech is discarded on timeout and is never sent to Gormes.
- Profile commands match the app's known flat `server + profile` contact list;
  exact normalized unique matches switch immediately, duplicates show
  disambiguation.
- Voice profile switching is a global app setting. If disabled, command-word
  profile switches are ignored and treated as normal dictation only when they
  are not recognized as local commands.
- `navi cancel` cancels the current cancellable voice turn. Before server
  commit it can discard/delete; after server commit it marks cancelled/stopped
  and never pretends tool side effects were undone.
- `navi settings` opens local Navivox settings, not profile config.
- Voice approvals and profile config edits by voice are deferred.
- Audio upload and playback state appear only after Voice run lifecycle state exists.
- Text fallback is always available.

### 2.6 Action Sheet

Use `DraggableScrollableSheet` for Telegram-like panels.

```text
+------------------------------------------------+
| Actions                                        |
+------------------------------------------------+
| New profile                                    |
| Tool approvals                                 |
| Workspace roots                                |
| Profile config                                 |
| Gateway details                                |
| Future file attach                             |
+------------------------------------------------+
```

Sheet rules:

- Snap between compact, half, and full height.
- Use the provided scroll controller so dragging and scrolling coordinate.
- Desktop gets a visible drag handle or side panel equivalent.
- Tokens and secret values never appear in sheet titles or route URLs.

### 2.7 Gateways Screen

```text
+------------------------------------------------+
| Gateways                                 [+]   |
+------------------------------------------------+
| local-gormes                                    |
| http://127.0.0.1:8765                           |
| Exposure: local    Auth: token required         |
| Health: OK         Stream: connected            |
| [Use] [Details]                                |
|                                                |
| tailnet-host                                    |
| http://100.64.1.2:8765                          |
| Exposure: tailscale   Auth: tailnet identity    |
| Health: offline                                |
| [Retry] [Details]                              |
+------------------------------------------------+
```

Server detail shows:

- Base URL.
- Health URL.
- Auth mode.
- Exposure mode.
- Token-required state.
- Last successful status.
- Last stream error.
- Redacted local credential status.
- Local trust for continuous voice.
- Capability summary: contacts, chat, voice input, schema config.

Continuous voice requires per-server local trust. The trust prompt shows safe
server identity/exposure/auth/capability evidence only.

### 2.8 Profile Editor

```text
+------------------------------------------------+
| Edit Profile                            [Save] |
+------------------------------------------------+
| Server: local-gormes                           |
| Profile ID: mineru                             |
| Display Name                                  |
| [ Mineru Builder                         ]     |
|                                                |
| Seed                                           |
| [ work on mineru repo                    ]     |
|                                                |
| Instructions                                   |
| [ concise coding assistant for this repo... ]  |
|                                                |
| Workspace Roots                                |
| mineru repo     repo       read-write    OK    |
| downloads       downloads  read-write    OK    |
| [Add Root]                                     |
+------------------------------------------------+
```

Profile creation starts with a short phrase and produces an editable draft:

- Server selection.
- Canonical profile id.
- Display name.
- Prompt/instructions.
- Provider/model draft, allowed to stay unset with a `model setup` attention
  badge.
- Tool set and permissions.
- Voice profile defaults for future server-side TTS/STT routing.
- Workspace root suggestions by label/purpose only; actual paths must be
  explicitly entered or confirmed.
- Safety and escalation notes.

Workspace root fields:

- `path`
- `label`
- `mode`: `read-only` or `read-write`
- `purpose`: `repo`, `downloads`, `docs`, `scratch`, or `other`
- server-returned health

Workspace root rules:

- Navivox sends add/remove/update requests; Gormes validates and persists.
- Gormes canonicalizes paths server-side and rejects dangerous or broad roots
  by policy.
- First version uses manual path entry plus server validation.
- Removing a root never deletes files.
- Applying root changes is blocked or deferred while the profile has active
  work, unless Gormes reports it is safe.
- A profile can exist with zero roots; filesystem tools remain disabled or
  setup-gated until roots exist.

### 2.9 Config Overview

```text
+------------------------------------------------+
| Config                                  Admin  |
+------------------------------------------------+
| Source: server schema                           |
| Secrets: redacted                               |
| Pending restart: no                             |
|                                                |
| Provider and Models                     >       |
| Voice Providers                         >       |
| Navivox Gateway                         >       |
| Tools and Approvals                     >       |
| Profiles                                >       |
| Security                                >       |
|                                                |
| [Reload Schema] [Review Pending Changes]       |
+------------------------------------------------+
```

### 2.10 Config Section

```text
+------------------------------------------------+
| Navivox Gateway                         [Back] |
+------------------------------------------------+
| Enabled                                  [x]   |
| Bind Host                                127.0.0.1 |
| Port                                     8765  |
| Exposure Mode                            local |
| Auth Mode                                static_token |
| Token                                    configured, redacted |
|                                                |
| [Set Token] [Test Connection]                  |
|                                                |
| Diff                                           |
| exposure_mode: local -> tailscale              |
|                                                |
| [Validate] [Apply]                             |
+------------------------------------------------+
```

Config rules:

- Secret values never render after entry.
- Diff shows non-secret before/after values.
- Server validation errors map to fields.
- Public exposure requires an explicit confirmation dialog.

### 2.11 Tool Call Card

```text
+-- execute_command ----------------------------+
| Status: completed                              |
| Duration: 0.3s                                 |
| Summary: uptime returned load averages         |
|                                                |
| [Inputs] [Output] [Artifacts]                  |
+------------------------------------------------+
```

Tool card states:

- queued
- running
- needs approval
- approved
- denied
- completed
- failed

Sensitive inputs and outputs are redacted by default with an explicit reveal
gate when the server allows it.

### 2.12 Settings Screen

```text
+------------------------------------------------+
| Settings                                       |
+------------------------------------------------+
| Appearance                                     |
| Theme: [Dark v]                                |
| Density: [Compact v]                           |
|                                                |
| Voice Defaults                                 |
| Command Word: [Navi]                           |
| Continuous Voice: [on]                         |
| Voice Profile Switching: [on]                  |
| Auto-send Grace: [1.5s]                        |
| [Calibrate Command Word]                       |
| [Reset Calibration]                            |
|                                                |
| Local Contact Preferences                      |
| Pinned contacts                                |
| Voice aliases                                  |
|                                                |
| Security                                       |
| App Lock: [on]                                 |
| Lock Timeout: [5 minutes v]                    |
|                                                |
| Data                                           |
| [Clear Local Cache]                            |
| [Forget This Gateway]                          |
|                                                |
| About                                          |
| Navivox 0.1.0                                  |
+------------------------------------------------+
```

## 3. Component Library

### 3.1 Shared Components

```dart
// Navigation
AppScaffold
ConnectionStatusBar
ServerSwitcher
ProfilePill
ErrorRecoverySheet

// Setup
ConnectInfoForm
HealthProbeStatus
TokenField
ExposureModeNotice

// Chat
MessageBubble
ToolCallCard
VoiceMessageBubble
TypingIndicator
DateSeparator
MessageComposer
VoiceControlBar
GlobalVoiceBar
CommandModeSheet

// Config
ConfigSectionCard
ConfigFormField
SecretStatusIndicator
ConfigDiffViewer
ApplyConfirmSheet
LocalUnlockGate

// Profiles
ProfileContactTile
ProfileAvatar
ProfileSeedInput
ProfileDraftEditor
WorkspaceRootsEditor
VoiceProfilePicker

// Gateways
ServerCard
GatewayStatusPanel
ReachabilityBadge

// Telegram-inspired surfaces
ChatPreviewTile
MessageActionSheet
ComposerShareSheet
ChatInfoActionSheet
NavivoxBubbleScope
```

## 4. Status And Error States

| State | UI Treatment | Primary Action |
|-------|--------------|----------------|
| Gateway offline | Red status chip, setup error | Retry health check |
| Unauthorized | Amber status chip | Enter token |
| Exposure blocked | Red notice | Fix server config |
| Stream disconnected | Reconnecting banner | Retry or edit connection |
| Inbox full | Assistant/system error | Try again |
| Tool failed | Failed tool card | Expand details |
| Secret denied | Field error | Request admin role or unlock |
| Workspace issue | Profile row attention badge | Open workspace roots |
| Voice disabled | Disabled mic with reason | Enable continuous voice |
| Server untrusted | Trust banner/sheet | Review and trust server |

All error copy should point to a next action and avoid raw provider errors or
secret-shaped values.

## 5. Visual Density

Mobile:

- Telegram-style bottom navigation for Chats, Profiles, Memory, and Settings.
- `More` overflow sheet for Gateways and Config on narrow screens.
- Single-column chat.
- Sheets for server/profile switching, chat info, composer share actions, and
  overflow destinations.
- Voice controls as bottom panel.

Desktop:

- Left rail.
- Persistent top/status bars.
- Optional split pane for config diffs and tool details.
- Keyboard-friendly command input.

## 6. Accessibility

- All icon buttons have labels/tooltips.
- Status chips have text, not color alone.
- Tool cards are keyboard expandable.
- Voice transcript can be cancelled during the grace window.
- Command mode has visible state, timeout, and cancel affordances.
- Secret fields describe state without exposing values.

## 7. Product Boundaries

Do now:

- Connect to gateway.
- Talk to a profile contact.
- Show structured tool activity.
- Seed editable profiles.
- Edit profile workspace roots through server APIs.
- Edit server/profile config through schema-driven server APIs.
- Support local command-word settings and continuous voice input.
- Record voice run metadata before streaming audio complexity.

Defer:

- Phone numbers.
- Outbound campaigns.
- Retry schedulers.
- Call routing.
- Human handoff.
- Generic server administration surfaces.
- Always-listening command-word detection.
- Voice-driven tool approvals or profile config mutations.
- Full session picker/history as a primary navigation surface.
- User-uploaded avatars.
- Telegram network clients, TDLib/MTProto, and Firebase chat backends.
