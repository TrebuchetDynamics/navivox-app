import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';
import 'package:navivox/features/settings/settings_screen_presentation.dart';
import 'package:navivox/router/app_routes.dart';

void main() {
  const presentation = SettingsScreenPresentation();

  test('centralizes static settings screen copy and management rows', () {
    expect(presentation.title, 'Voice settings');
    expect(presentation.globalTitle, 'Global app settings');
    expect(
      presentation.globalSubtitle,
      'Voice controls stay local to this app. Gateway and profile settings live in their own screens.',
    );

    expect(
      presentation.managementRows.map(
        (row) => '${row.keyValue}:${row.title}:${row.subtitle}:${row.route}',
      ),
      [
        'settings-manage-gateways:Manage gateways:Add, test, edit, and remove Gormes gateway connections.:${AppRoutes.servers}',
        'settings-manage-profiles:Manage profile contacts:Create, refresh, edit, or select profiles from the Agents tab.:${AppRoutes.agents}',
      ],
    );

    expect(presentation.continuousVoiceTitle, 'Continuous voice');
    expect(
      presentation.continuousVoiceSubtitle,
      'Use local device STT for the active profile',
    );
    expect(presentation.commandWordTitle, 'Command word');
    expect(presentation.profileSwitchingTitle, 'Voice profile switching');
    expect(
      presentation.profileSwitchingSubtitle,
      'Allow local command-word profile switches',
    );
  });

  test('builds management summary with singular and plural labels', () {
    expect(
      presentation.managementOverview(serverCount: 1, profileContactCount: 1),
      const SettingsManagementOverviewPresentation(
        keyValue: 'settings-management-overview',
        title: 'Management overview',
        subtitle: '1 Gormes gateway · 1 profile contact',
      ),
    );

    expect(
      presentation.managementOverview(serverCount: 2, profileContactCount: 3),
      const SettingsManagementOverviewPresentation(
        keyValue: 'settings-management-overview',
        title: 'Management overview',
        subtitle: '2 Gormes gateways · 3 profile contacts',
      ),
    );
  });

  test('builds trust row state for the active Gormes gateway', () {
    const server = NavivoxServer(
      id: 'local',
      name: 'Local Gormes',
      status: 'online',
    );

    expect(
      presentation.trustRowFor(server, settings: const NavivoxVoiceSettings()),
      const SettingsTrustRowPresentation(
        keyValue: 'voice-trust-local',
        title: 'Trust Local Gormes for voice',
        subtitle: 'Local-only trust, not server config',
        trusted: false,
      ),
    );

    expect(
      presentation
          .trustRowFor(
            server,
            settings: const NavivoxVoiceSettings(trustedServerIds: {'local'}),
          )
          .trusted,
      isTrue,
    );
  });

  test('builds current session scope rows and health labels', () {
    const server = NavivoxServer(
      id: 'local',
      name: 'Local Gormes',
      status: 'online',
    );
    const profile = NavivoxProfileContact(
      serverId: 'local',
      profileId: 'mineru',
      displayName: 'Mineru Builder',
      serverLabel: 'local',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
    );

    final scope = presentation.currentScopeFor(
      activeServer: server,
      activeProfile: profile,
    );

    expect(scope, isNotNull);
    expect(scope!.title, 'Current session scope');
    expect(
      scope.subtitle,
      'Local settings apply to the currently selected gateway and profile contact.',
    );
    expect(
      scope.gateway,
      const SettingsScopeRowPresentation(
        keyValue: 'settings-current-gateway',
        title: 'Active Gormes gateway',
        subtitle: 'Local Gormes · local · online',
      ),
    );
    expect(
      scope.profile,
      const SettingsScopeRowPresentation(
        keyValue: 'settings-current-profile',
        title: 'Active profile contact',
        subtitle: 'Mineru Builder · local/mineru · online',
      ),
    );

    expect(
      presentation.currentScopeFor(activeServer: null, activeProfile: null),
      isNull,
    );
    expect(presentation.healthLabel(NavivoxProfileHealth.online), 'online');
    expect(presentation.healthLabel(NavivoxProfileHealth.offline), 'offline');
    expect(presentation.healthLabel(NavivoxProfileHealth.needsAuth), 'auth');
    expect(presentation.healthLabel(NavivoxProfileHealth.warning), 'warning');
  });
}
