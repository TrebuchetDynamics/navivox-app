# Navivox Route Design

Status: historical Gormes route plan plus active Hermes route addendum
Updated: 2026-07-03
Source: derived from docs/product/prd.md and the current Flutter router (`lib/router/routes/app_routes.dart`, `lib/router/providers/app_router.dart`)

## 1. Route Architecture

GoRouter uses Riverpod state to decide whether the app should show setup, the
legacy Gormes shell, or the native Hermes screen. Current `initialLocation` is
`AppRoutes.hermes` when no legacy Gormes server is connected, and `AppRoutes.chats`
when preserved Gormes state already has a server (`lib/router/providers/app_router.dart:22`).
The `/hermes` route is allowed through the setup redirect without a Gormes gateway
(`lib/router/providers/app_router.dart:27`).

The sections below preserve the original Gormes-first route plan and add the
active Hermes route where it now exists.

### 1.1 Current Route Constants

```dart
abstract final class AppRoutes {
  static const setup = '/setup';
  static const chats = '/chats';
  static const chatThread = '/chats/:serverId/:profileId';
  static const servers = '/servers';
  static const serverDetail = '/servers/:id';
  static const memory = '/memory';
  static const agents = '/agents';
  static const agentEditor = '/agents/:id/edit';
  static const agentCreate = '/agents/create';
  static const config = '/config';
  static const configSection = '/config/:section';
  static const secretEditor = '/config/secrets/:key';
  static const terminal = '/terminal';
  static const terminalSession = '/terminal/:serverId';
  static const settings = '/settings';
  static const hermes = '/hermes';

  static String chatLocation({
    required String serverId,
    required String profileId,
  }) => '/chats/<encoded server>/<encoded profile>';

  static String configSectionLocation(String sectionId) =>
      '/config/<encoded section>';

  static bool isSetupLocation(String location) =>
      location == setup || location.startsWith('$setup/');

  static bool isHermesLocation(String location) =>
      location == hermes || location.startsWith('$hermes/');

  static bool isChatThreadLocation(String location) =>
      location.startsWith('$chats/');
}
```

Setup, chats, chat thread, servers, agents, memory, config, config section,
settings, and `/hermes` are currently mounted in the router. Server detail,
agent editor, agent create, secret editor, terminal, and terminal session constants
remain future surfaces until their screens have current gateway-backed behavior.

Profile contact chat locations must be built through `AppRoutes.chatLocation`
so `server_id` and `profile_id` values with spaces or slashes are encoded as
route path segments before GoRouter matching.

## 2. Current Route Table

### 2.1 Hermes and setup entry points

| Path | Screen | Guard | Notes |
|------|--------|-------|-------|
| `/hermes` | `HermesChatScreen` | None; setup redirect allows it without legacy Gormes state | Native Hermes Agent connect/session/chat/voice surface. API keys are entered only into the Hermes form/store path, not routes. |
| `/setup` | `SetupScreen` | None | Legacy Gormes setup: paste or scan `gormes navivox connect-info` output, enter token when required, probe `/healthz`, and connect to the stream. |

The Hermes route is the fresh-install default. The legacy setup screen should
still prefer a single "connect and talk now" path for Gormes. Advanced server
inventory, imports, and terminal workflows are not part of the first activation
loop.

### 2.2 Main Shell

The shell route wraps the primary authenticated surfaces with app navigation.

| Tab | Path | Screen | Guard |
|-----|------|--------|-------|
| Chats | `/chats` | `ChatScreen` | Connected gateway |
| Gateways | `/servers` | `ServersScreen` | Connected gateway |
| Profiles | `/agents` | `AgentsScreen` | Connected gateway |
| Memory | `/memory` | `MemoryDashboardScreen` | Connected gateway |
| Config | `/config`, `/config/:section` | `ConfigScreen` | Connected gateway; mutation controls require server role evidence |
| Hermes | `/hermes` | `HermesChatScreen` | Native Hermes endpoint/session UI; not gated by Gormes server state |

### 2.3 Planned Detail Routes

| Path | Screen | Guard | Notes |
|------|--------|-------|-------|
| `/chats/:serverId/:threadId` | `ChatScreen` with session context | Connected gateway | Open an existing Navivox session from the local cache or server session list. |
| `/servers/:id` | `ServerDetailScreen` | Connected gateway | Show base URL, health, exposure mode, auth mode, and redacted token status. |
| `/agents/:id/edit` | `AgentEditorScreen` | Admin role | Edit generated agent/profile/tool/voice settings after a seed flow. |
| `/agents/create` | `AgentCreateScreen` | Admin role | Natural-language seed such as "screen inbound leads". |
| `/config/:section` | `ConfigScreen` with section context | Connected gateway; mutation controls require server role evidence | Mounted; filters schema sections by id and shows a safe missing-section state for unknown ids. |
| `/config/secrets/:key` | `SecretEditorScreen` | Admin role + local unlock | Set, rotate, delete, and test a secret without reading its value. |
| `/settings` | `SettingsScreen` | Local app | Theme, local voice defaults, cache controls, and app lock. |
| `/terminal` | Future terminal surface | Explicit opt-in | Deferred; not part of the connect-and-talk loop. |

## 3. Router Configuration

The current provider redirects to legacy setup until a gateway-backed server is
present, but exempts `/hermes` so a fresh install opens the native Hermes flow.
This excerpt is intentionally shortened; verify changes against
`lib/router/providers/app_router.dart`.

```dart
return GoRouter(
  initialLocation: channel.state.servers.isEmpty
      ? AppRoutes.hermes
      : AppRoutes.chats,
  redirect: (context, state) {
    final hasServers = channel.state.servers.isNotEmpty;
    final isSetup = AppRoutes.isSetupLocation(state.matchedLocation);
    final isHermes = AppRoutes.isHermesLocation(state.uri.toString());

    if (!hasServers && !isSetup && !isHermes) return AppRoutes.setup;
    if (hasServers && isSetup) return AppRoutes.chats;
    return null;
  },
  routes: [
    GoRoute(path: AppRoutes.setup, builder: (_, __) => const SetupScreen()),
    ShellRoute(
      builder: (_, state, child) => AppShell(
        location: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(path: AppRoutes.chats, builder: (_, __) => const ProfileContactsScreen()),
        GoRoute(path: AppRoutes.chatThread, builder: (_, state) => ChatScreen(...)),
        GoRoute(path: AppRoutes.servers, builder: (_, __) => const ServersScreen()),
        GoRoute(path: AppRoutes.agents, builder: (_, __) => const AgentsScreen()),
        GoRoute(path: AppRoutes.memory, builder: (_, __) => const MemoryDashboardScreen()),
        GoRoute(path: AppRoutes.config, builder: (_, __) => const ConfigScreen()),
        GoRoute(path: AppRoutes.configSection, builder: (_, state) => ConfigScreen(...)),
        GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
        GoRoute(path: AppRoutes.hermes, builder: (_, __) => const HermesChatScreen()),
      ],
    ),
  ],
);
```

## 4. Route Guards

### 4.1 Connection Guard

```dart
final hasGatewayProvider = Provider<bool>((ref) {
  final channel = ref.watch(navivoxChannelProvider);
  return channel.state.servers.isNotEmpty;
});
```

Legacy Gormes setup owns Gormes connection creation. `/hermes` owns its own
Hermes endpoint connection form and saved-endpoint store, so it is not blocked
by `hasGatewayProvider`. The shell renders connection loss as recoverable UI,
not a route crash.

### 4.2 Role Guards

Role evidence comes from the server. Until the gateway exposes role metadata,
mutation actions are disabled or shown as "not available yet".

```dart
final canMutateConfigProvider = Provider<bool>((ref) {
  final role = ref.watch(activeServerRoleProvider);
  return role == NavivoxRole.owner || role == NavivoxRole.admin;
});
```

### 4.3 Inline Widget Guards

Fine-grained controls use inline guards instead of hiding whole screens.

```dart
class ConfigMutationGuard extends ConsumerWidget {
  const ConfigMutationGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canMutateConfigProvider)) {
      return const ReadOnlyConfigView();
    }
    return child;
  }
}
```

## 5. Navigation Patterns

### 5.1 Hermes setup to chat

```text
Open /hermes
  -> enter Hermes API base URL + optional API key
  -> GET /health and /v1/capabilities
  -> GET/POST /api/sessions
  -> POST /api/sessions/{id}/chat/stream or /v1/runs when capability-gated
```

### 5.2 Legacy Gormes setup to chat

```text
Paste connect-info base URL + token
  -> GET /healthz
  -> GET /v1/navivox/status
  -> WS /v1/navivox/stream
  -> Navigate to /chats
```

### 5.2 Server Switcher

The server switcher changes the active gateway context without leaving chat.
Switching servers reconnects the `GatewayNavivoxChannel` and refreshes status.

### 5.3 Agent Switcher

The agent picker is a sheet/menu from chat. Agent selection updates local UI
state immediately and sends a gateway request once agent selection is exposed by
the channel contract.

### 5.4 Deep Links

Deep links are local app links. They never include tokens.

```text
navivox://chat/<serverId>/<threadId>
navivox://server/<serverId>
navivox://config/<serverId>/<section>
```

## 6. Mobile Navigation Layout

```text
+---------------------+
| App Bar             |  Server name, agent pill, connection status
|                     |
| Content Area        |
| (GoRouter child)    |
|                     |
+---------------------+
| Chats | Srv | Agt   |
| Config              |
+---------------------+
```

## 7. Desktop Navigation Layout

```text
+------+----------------------------------+
|      | Top Bar                          |
| Left | Server: local  Agent: default    |
| Rail +----------------------------------+
|      | Content Area                     |
| Chat | (GoRouter child)                 |
| Srv  |                                  |
| Agt  |                                  |
| Cfg  |                                  |
+------+----------------------------------+
| Status Bar: gateway, version, auth      |
+-----------------------------------------+
```

## 8. First-Run Flow Navigation

The first-run wizard uses internal step state rather than many routes:

```text
Step 1: Paste or scan connect-info
Step 2: Enter token when required
Step 3: Probe health and status
Step 4: Open stream
Step 5: Land in chat with a starter prompt
```

Optional later steps can help create an agent from a short natural-language
seed, but the operator should be able to talk before completing advanced
configuration.

## 9. Route Transition Animations

| Transition | Use Case |
|------------|----------|
| Slide right to left | Push to detail screens |
| Slide left to right | Pop back |
| Fade through | Tab switches in shell |
| Modal bottom sheet | Agent switcher, quick actions |
| Full-screen dialog | Secret editor and destructive confirmations |
