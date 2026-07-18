part of 'settings_screen.dart';

class DiagnosticsSettingsScreen extends ConsumerWidget {
  const DiagnosticsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(hermesChannelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: AnimatedBuilder(
        animation: channel,
        builder: (context, _) {
          final state = channel.state;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSectionCard(
                title: 'Connection',
                icon: Icons.cable_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.circle,
                    title: 'Status',
                    value: _connectionStatusLabel(state.status),
                  ),
                  _StatusTile(
                    icon: Icons.memory_outlined,
                    title: 'Model',
                    value: state.models.isEmpty
                        ? state.capabilities?.model ?? 'Not reported'
                        : state.models.first,
                  ),
                  _StatusTile(
                    icon: Icons.account_tree_outlined,
                    title: 'Run transport',
                    value: _runTransportLabel(state),
                  ),
                  _StatusTile(
                    icon: Icons.info_outline,
                    title: 'Version / health',
                    value: _healthLabel(state),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Inventory',
                icon: Icons.checklist_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Resources',
                    value:
                        '${state.models.length} models • ${state.skills.length} skills • ${state.enabledToolsets.length} toolsets • ${state.jobs.length} jobs',
                  ),
                  if (state.optionalResourceErrors.isNotEmpty)
                    _StatusTile(
                      icon: Icons.warning_amber_outlined,
                      title: 'Inventory warnings',
                      value: _optionalResourceWarningLabel(
                        state.optionalResourceErrors.keys,
                      ),
                    ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Sessions',
                icon: Icons.chat_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.chat_outlined,
                    title: 'Sessions',
                    value:
                        '${state.sessions.length} sessions • active ${state.activeSessionId == null ? 'none' : 'yes'}',
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: 'Export',
                icon: Icons.copy_outlined,
                children: [
                  ListTile(
                    key: const ValueKey('settings-copy-diagnostics'),
                    leading: const Icon(Icons.copy_outlined),
                    title: const Text('Copy diagnostics'),
                    subtitle: const Text(
                      'Safe snapshot; excludes secrets, raw logs, transcripts, and local paths.',
                    ),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: hermesDiagnosticsExport(state)),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hermes diagnostics copied'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

String _connectionStatusLabel(HermesConnectionStatus status) =>
    switch (status) {
      HermesConnectionStatus.disconnected => 'Disconnected',
      HermesConnectionStatus.connecting => 'Connecting',
      HermesConnectionStatus.connected => 'Connected',
      HermesConnectionStatus.error => 'Error',
    };

String _runTransportLabel(HermesChannelState state) {
  final capabilities = state.capabilities;
  if (capabilities == null) return 'Not connected';
  final policy = HermesTransportPolicy(capabilities);
  if (policy.supportsRunsTransport) return 'Runs SSE enabled';
  if (policy.supportsSessionChatStream) return 'Session chat streaming';
  return 'Unavailable';
}

String _healthLabel(HermesChannelState state) {
  final health = state.detailedHealth;
  if (health == null) return state.errorMessage ?? 'No health details yet';
  final version = health.version ?? 'unknown version';
  final gateway = health.gatewayState ?? 'unknown gateway';
  return '$version • $gateway';
}

String _optionalResourceWarningLabel(
  Iterable<HermesOptionalResource> resources,
) {
  final labels =
      resources
          .map(
            (resource) => switch (resource) {
              HermesOptionalResource.detailedHealth => 'health',
              HermesOptionalResource.models => 'models',
              HermesOptionalResource.skills => 'skills',
              HermesOptionalResource.toolsets => 'toolsets',
              HermesOptionalResource.jobs => 'jobs',
            },
          )
          .toList()
        ..sort();
  final summary = labels.join(', ');
  return '${summary[0].toUpperCase()}${summary.substring(1)} unavailable';
}
