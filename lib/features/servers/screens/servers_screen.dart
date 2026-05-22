import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navivoxChannelProvider).state;
    final servers = [...state.servers]
      ..sort((a, b) => a.name.compareTo(b.name));
    final contactsByServer = <String, List<NavivoxProfileContact>>{};
    for (final contact in state.profileContacts) {
      contactsByServer.putIfAbsent(contact.serverId, () => []).add(contact);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gateways')),
      body: servers.isEmpty
          ? const Center(child: Text('No gateways registered'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: servers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final server = servers[index];
                final contacts = contactsByServer[server.id] ?? const [];
                final active = server.id == state.activeServerId;
                return _ServerCard(
                  server: server,
                  contacts: contacts,
                  active: active,
                  onManage: () => _showManageGateway(
                    context,
                    ref.read(navivoxChannelProvider),
                    server,
                    contacts,
                    active: active,
                    activeProfile: state.activeProfileContact,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Register gateway',
        onPressed: () =>
            _showRegisterGateway(context, ref.read(navivoxChannelProvider)),
        icon: const Icon(Icons.add_link),
        label: const Text('Register'),
      ),
    );
  }

  void _showManageGateway(
    BuildContext context,
    NavivoxChannel channel,
    NavivoxServer server,
    List<NavivoxProfileContact> contacts, {
    required bool active,
    NavivoxProfileContact? activeProfile,
  }) {
    final activeProfileOnGateway =
        activeProfile != null && activeProfile.serverId == server.id
        ? activeProfile
        : null;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Manage gateway',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns),
              title: Text(server.name),
              subtitle: Text(server.status),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.tag),
              title: Text('Server ID'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 12),
              child: SelectableText(server.id),
            ),
            if (activeProfileOnGateway != null) ...[
              const Divider(),
              ListTile(
                key: ValueKey('server-active-profile-${server.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Active profile contact'),
                subtitle: Text(
                  '${activeProfileOnGateway.displayName} · ${activeProfileOnGateway.profileId}',
                ),
              ),
            ],
            if (active) ...[
              const Divider(),
              ListTile(
                key: const ValueKey('server-disconnect-current'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_off),
                title: const Text('Disconnect current session'),
                subtitle: const Text(
                  'Close the active Gormes gateway connection for this app session.',
                ),
                onTap: () => _confirmDisconnect(context, channel, server),
              ),
            ],
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.people_alt_outlined),
              title: Text('Profiles on this gateway'),
            ),
            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Text('No profiles reported by this gateway yet.'),
              )
            else
              for (final contact in contacts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      contact.displayName.characters.first.toUpperCase(),
                    ),
                  ),
                  title: Text(contact.displayName),
                  subtitle: Text(contact.profileId),
                  trailing: _HealthPill(health: contact.health),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    NavivoxChannel channel,
    NavivoxServer server,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect ${server.name}?'),
        content: const Text(
          'Navivox will close the active gateway session. Stored app settings stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('server-disconnect-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await channel.disconnect();
      if (!context.mounted) return;
      await Navigator.of(context).maybePop();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Disconnected ${server.name}')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Disconnect failed: $error')));
    }
  }

  void _showRegisterGateway(BuildContext context, NavivoxChannel channel) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _RegisterGatewaySheet(channel: channel),
    );
  }
}

class _RegisterGatewaySheet extends StatefulWidget {
  const _RegisterGatewaySheet({required this.channel});

  final NavivoxChannel channel;

  @override
  State<_RegisterGatewaySheet> createState() => _RegisterGatewaySheetState();
}

class _RegisterGatewaySheetState extends State<_RegisterGatewaySheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _testing = false;

  @override
  void dispose() {
    _labelController.dispose();
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.add_link),
                title: Text('Register gateway'),
                subtitle: Text(
                  'Run `gormes navivox connect-info --json` on the server, then enter its base URL and auth token here.',
                ),
              ),
              TextFormField(
                key: const ValueKey('register-gateway-label'),
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Gateway label',
                  helperText: 'Screen-reader friendly name for this device.',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('register-gateway-base-url'),
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'http://127.0.0.1:7319',
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: _validateBaseUrl,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('register-gateway-token'),
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Auth token (optional)',
                  helperText: 'Stored by the gateway connection layer only.',
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('register-gateway-test'),
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                  label: Text(_testing ? 'Testing' : 'Test connection'),
                ),
              ),
              const SizedBox(height: 12),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline),
                title: Text('Current boundary'),
                subtitle: Text(
                  'This test connects the current session now; persistent multi-gateway connection storage is the next protocol slice.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateBaseUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the Gormes gateway base URL.';
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return 'Enter a valid Gormes gateway URL.';
    }
    if (!{'http', 'https', 'ws', 'wss'}.contains(uri.scheme)) {
      return 'Use http, https, ws, or wss.';
    }
    return null;
  }

  Future<void> _testConnection() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final baseUrl = _baseUrlController.text.trim();
    final token = _tokenController.text.trim();
    setState(() => _testing = true);
    try {
      await widget.channel.connect(
        baseUrl: baseUrl,
        token: token.isEmpty ? null : token,
      );
      if (!mounted) return;
      _showSnackBar('Connection test passed for $baseUrl');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Connection test failed: $error');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(duration: const Duration(seconds: 8), content: Text(message)),
      );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.server,
    required this.contacts,
    required this.active,
    required this.onManage,
  });

  final NavivoxServer server;
  final List<NavivoxProfileContact> contacts;
  final bool active;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final warningCount = contacts
        .where(
          (c) =>
              !c.workspaceRootsOk || c.health == NavivoxProfileHealth.warning,
        )
        .length;
    final authCount = contacts
        .where((c) => c.health == NavivoxProfileHealth.needsAuth)
        .length;
    final activeTurns = contacts
        .where((c) => c.activeTurnState != 'idle')
        .length;

    return Card(
      key: ValueKey('server-card-${server.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(active ? Icons.hub : Icons.dns),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        server.status,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('server-manage-${server.id}'),
                  tooltip: 'Manage ${server.name}',
                  onPressed: onManage,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CountChip(label: _plural(contacts.length, 'profile')),
                if (warningCount > 0)
                  _CountChip(label: _plural(warningCount, 'warning')),
                if (authCount > 0)
                  _CountChip(label: _plural(authCount, 'auth')),
                if (activeTurns > 0)
                  _CountChip(label: _plural(activeTurns, 'active turn')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _plural(int count, String noun) {
    if (count == 1) return '1 $noun';
    return '$count ${noun}s';
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(visualDensity: VisualDensity.compact, label: Text(label));
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.health});

  final NavivoxProfileHealth health;

  @override
  Widget build(BuildContext context) {
    final label = switch (health) {
      NavivoxProfileHealth.online => 'online',
      NavivoxProfileHealth.offline => 'offline',
      NavivoxProfileHealth.needsAuth => 'auth',
      NavivoxProfileHealth.warning => 'warning',
    };
    return Text(label, style: Theme.of(context).textTheme.labelSmall);
  }
}
