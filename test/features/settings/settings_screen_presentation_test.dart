import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/settings/settings_screen_presentation.dart';
import 'package:navivox/shared/voice/voice_settings.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/shared/presentation/profile_health_labels.dart';

void main() {
  const presentation = SettingsScreenPresentation();

  test('centralizes static settings screen copy and management rows', () {
    expect(presentation.title, 'Settings');
    expect(presentation.localSettingsTitle, 'Local settings');
    expect(
      presentation.localSettingsSubtitle,
      'Preferences on this Navivox install. Gormes config, profile contacts, and gateway auth live in their own surfaces.',
    );
    expect(presentation.localVoiceSectionTitle, 'Local voice preferences');
    expect(
      presentation.localVoiceSectionSubtitle,
      'Command word, local capture, and voice trust stay in Navivox.',
    );

    expect(
      presentation.managementRows.map(
        (row) => '${row.keyValue}:${row.title}:${row.subtitle}:${row.route}',
      ),
      [
        'settings-manage-gateways:Manage gateways:Add, test, edit, and remove Gormes gateway connections.:${AppRoutes.servers}',
        'settings-manage-profiles:Manage profile contacts:Create, refresh, edit, or select Profile contacts from the Profiles tab.:${AppRoutes.agents}',
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
    expect(compactProfileHealthLabel(NavivoxProfileHealth.online), 'online');
    expect(compactProfileHealthLabel(NavivoxProfileHealth.offline), 'offline');
    expect(compactProfileHealthLabel(NavivoxProfileHealth.needsAuth), 'auth');
    expect(compactProfileHealthLabel(NavivoxProfileHealth.warning), 'warning');
  });
}
