import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/navigation_intent.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../providers/voice_settings_provider.dart';
import '../presentation/settings_screen_presentation.dart';

const _settingsPresentation = SettingsScreenPresentation();

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(navivoxChannelProvider);
    final settings = ref.watch(navivoxVoiceSettingsProvider);
    final controller = ref.read(navivoxVoiceSettingsProvider.notifier);
    final activeServer = channel.state.activeServer;
    final activeProfile = channel.state.activeProfileContact;
    final managementOverview = _settingsPresentation.managementOverview(
      serverCount: channel.state.servers.length,
      profileContactCount: channel.state.profileContacts.length,
    );
    final activeServerTrust = activeServer == null
        ? null
        : _settingsPresentation.trustRowFor(activeServer, settings: settings);
    final currentScope = _settingsPresentation.currentScopeFor(
      activeServer: activeServer,
      activeProfile: activeProfile,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_settingsPresentation.title)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_applications),
            title: Text(_settingsPresentation.globalTitle),
            subtitle: Text(_settingsPresentation.globalSubtitle),
          ),
          for (final row in _settingsPresentation.managementRows)
            ListTile(
              key: ValueKey(row.keyValue),
              leading: Icon(_managementRouteIcon(row)),
              title: Text(row.title),
              subtitle: Text(row.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(row.route),
            ),
          const Divider(),
          SwitchListTile(
            key: const ValueKey('voice-continuous-enabled'),
            title: Text(_settingsPresentation.continuousVoiceTitle),
            subtitle: Text(_settingsPresentation.continuousVoiceSubtitle),
            value: settings.continuousVoiceEnabled,
            onChanged: controller.setContinuousVoiceEnabled,
          ),
          ListTile(
            key: const ValueKey('settings-command-word'),
            title: Text(_settingsPresentation.commandWordTitle),
            subtitle: Text(settings.commandWord),
            trailing: const Icon(Icons.keyboard_voice),
            onTap: () => _showCommandWordSheet(context, settings.commandWord),
          ),
          SwitchListTile(
            key: const ValueKey('voice-profile-switching-enabled'),
            title: Text(_settingsPresentation.profileSwitchingTitle),
            subtitle: Text(_settingsPresentation.profileSwitchingSubtitle),
            value: settings.profileSwitchingEnabled,
            onChanged: controller.setProfileSwitchingEnabled,
          ),
          if (activeServer != null && activeServerTrust != null)
            SwitchListTile(
              key: ValueKey(activeServerTrust.keyValue),
              title: Text(activeServerTrust.title),
              subtitle: Text(activeServerTrust.subtitle),
              value: activeServerTrust.trusted,
              onChanged: (trusted) =>
                  controller.setServerTrusted(activeServer.id, trusted),
            ),
          ListTile(
            key: ValueKey(managementOverview.keyValue),
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(managementOverview.title),
            subtitle: Text(managementOverview.subtitle),
          ),
          if (currentScope != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.route_outlined),
              title: Text(currentScope.title),
              subtitle: Text(currentScope.subtitle),
            ),
            if (currentScope.gateway != null)
              ListTile(
                key: ValueKey(currentScope.gateway!.keyValue),
                leading: const Icon(Icons.dns_outlined),
                title: Text(currentScope.gateway!.title),
                subtitle: Text(currentScope.gateway!.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NavigationIntent.go(context, const OpenGateways()),
              ),
            if (currentScope.profile != null)
              ListTile(
                key: ValueKey(currentScope.profile!.keyValue),
                leading: const Icon(Icons.badge_outlined),
                title: Text(currentScope.profile!.title),
                subtitle: Text(currentScope.profile!.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NavigationIntent.go(context, const OpenAgents()),
              ),
          ],
        ],
      ),
    );
  }
}

void _showCommandWordSheet(BuildContext context, String commandWord) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.keyboard_voice),
            title: Text(_settingsPresentation.commandWordTitle),
            subtitle: Text(
              'Say "$commandWord" before local commands like profile names, stop, cancel, settings, or help. Command-word editing will live here when local voice customization lands.',
            ),
          ),
        ],
      ),
    ),
  );
}

IconData _managementRouteIcon(SettingsManagementRoutePresentation row) {
  return switch (row.keyValue) {
    'settings-manage-gateways' => Icons.dns_outlined,
    'settings-manage-profiles' => Icons.badge_outlined,
    _ => Icons.chevron_right,
  };
}
