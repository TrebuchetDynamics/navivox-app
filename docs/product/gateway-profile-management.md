# Gateway profile management and limitations

## What this is

Hermes Wing can manage Hermes profiles separately on each saved gateway. Start
in **Settings → Gateways → gateway menu → Manage agents**, or open **Agents**
and choose a gateway from the gateway selector. The selected gateway remains
the authority for every profile read and mutation.

This page documents the supported operations, capability requirements, and
hard boundaries. It does not describe or authorize changes to Hermes Agent.

## Terms

- **Gateway**: one saved Hermes API endpoint and credential.
- **Profile / agent**: a server-owned Hermes profile exposed by that gateway.
- **Active gateway**: the gateway currently using Wing's single full channel.
  Switching gateways disconnects the previous active channel before connecting
  the selected one (`lib/features/hermes_chat/gateways/hermes_gateway_directory.dart:395-418`).

Gateway settings and Hermes profiles are different resources. Renaming or
removing a saved gateway does not rename or delete its server-owned profiles.

## Supported Wing workflow

| Operation | Wing behavior | Required advertised access |
| --- | --- | --- |
| List profiles | Shows profiles returned by the selected gateway | `GET /api/profiles`, `profiles:read` |
| Create | Creates a named profile, optionally cloned from an existing profile | `POST /api/profiles`, `profiles:write` |
| Rename | Changes the profile display name with its current revision | `PATCH /api/profiles/{name}`, `profiles:write` |
| Edit persona | Reads and writes the profile's SOUL/persona text | `GET` and `PUT /api/profiles/{name}/soul`, profile read/write scopes |
| Delete | Requires typed confirmation; the default profile cannot be deleted | `DELETE /api/profiles/{name}`, `profiles:write` |
| Chat | Selects that profile as client context without changing Hermes CLI state | Profile query-context support |

The editor calls the channel's create, rename, persona-write, and delete
operations directly (`lib/features/agents/widgets/profile_editor_sheet.dart:75-139`).
The channel checks each advertised endpoint before network I/O
(`lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart:114-205`).
Settings exposes **Manage agents** for every saved gateway
(`lib/features/settings/screens/settings_screen.dart:149-170`), while the
Agents screen also provides a gateway selector
(`lib/features/agents/screens/agents_screen.dart:198-246`).

## Capability and authorization requirements

Profile management is available only when the authenticated
`GET /v1/capabilities` response:

1. uses a supported capability schema;
2. advertises `GET /api/profiles`;
3. grants `profiles:read` for listing;
4. advertises and grants `profiles:write` for each requested mutation; and
5. advertises the expected method and canonical `{name}` route template.

Wing checks schema, scope, method, and path together before showing controls
(`lib/features/agents/screens/agents_screen.dart:300-317`). Read-only
credentials may list profiles but do not see create, edit, or delete controls.
An endpoint advertised under a different method or route template is treated
as a different contract, not guessed. Background gateway summaries apply the
same `profiles:read` check before requesting `/api/profiles`. They issue
profile-qualified session reads only when `profile_context` declares the exact
required `profile` query contract; otherwise Wing falls back to the gateway's
unscoped default contact rather than exposing nonfunctional profile contacts or
inferring query semantics.

Mutations are revisioned. Rename, persona update, and delete use the server's
opaque revision as an `If-Match` precondition. A stale `412` response refreshes
the profile list and surfaces a conflict instead of overwriting newer state
(`lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart:214-285`).

## Hard limitations

### Wing cannot manufacture server-owned profiles

If a gateway does not advertise the profile endpoints, Hermes Wing cannot add,
edit, or delete real Hermes profiles on that gateway. Wing does not create a
local shadow profile, parse Hermes files, invoke Hermes CLI output, or probe
unadvertised administration routes. Hermes Agent remains the sole domain
authority under [ADR 0012](../adr/0012-hermes-agent-domain-authority.md).

### Hermes Agent is outside this repository

This repository does not modify, patch, deploy, or restart Hermes Agent.
Compatibility work in Wing is limited to consuming the gateway's advertised
HTTP contract. Missing server support must remain visible as unavailable; it
must not be bypassed in the client.

### One full gateway channel is active at a time

Profile management switches Wing's active gateway. This can close the current
chat connection before opening the selected gateway. Inactive gateways retain
only lightweight/cached summaries; they do not each keep a full streaming
channel (`lib/features/hermes_chat/gateways/hermes_gateway_directory.dart:395-441`).

### No offline administrative replay

Profile mutations require a live authorized gateway. Failed or interrupted
mutations are not queued or replayed later, per
[ADR 0030](../adr/0030-no-offline-mutation-replay.md).

### The editor is intentionally bounded

The current editor supports name, clone source, persona text, and safe deletion.
It does not expose every Hermes Desktop profile-builder field, provider secret,
model assignment, skill configuration, runtime setting, or raw profile file.
Those surfaces require their own advertised, scoped contracts.

### Cached fallback contacts are not proof of profile support

A gateway without advertised profile discovery may still appear as a single
fallback **Default agent** contact so its unscoped chat sessions remain usable.
That fallback is navigation compatibility, not evidence that profile CRUD is
available (`lib/features/hermes_chat/gateways/hermes_gateway_directory.dart:200-213`).

## Troubleshooting

When **Agents unavailable** appears for a selected gateway:

1. Confirm the gateway is online and the intended gateway is selected.
2. Inspect its authenticated `/v1/capabilities` response without recording the
   bearer credential.
3. Verify `profiles:read`, and `profiles:write` when mutations are required.
4. Verify the exact operations and `{name}` paths listed above.
5. Reconnect or re-enroll the gateway if its saved credential has insufficient
   scope.

Do not work around a missing capability by entering secrets in URLs, exposing a
local dashboard port, parsing server files, or adding client-side profile state.

## Evidence and update triggers

Focused tests cover gateway activation, gateway-menu discovery, canonical Agent
route placeholders, profile editing, authorization gating, conflict handling,
and deletion confirmation:

- `test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart:60`
- `test/features/settings/settings_screen_test.dart:90`
- `test/features/agents/agents_screen_test.dart:104`
- `test/core/hermes/channel/hermes_api_channel_test.dart`
- `test/features/agents/profile_editor_sheet_test.dart`

Revisit this page when profile endpoint names, route templates, scopes,
revision semantics, gateway channel topology, or editor fields change.
