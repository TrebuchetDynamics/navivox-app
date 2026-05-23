import '../../core/channel/navivox_channel.dart';
import '../../router/app_routes.dart';
import 'providers/voice_settings_provider.dart';

class SettingsScreenPresentation {
  const SettingsScreenPresentation();

  String get title => 'Voice settings';

  String get globalTitle => 'Global app settings';

  String get globalSubtitle =>
      'Voice controls stay local to this app. Gateway and profile settings live in their own screens.';

  List<SettingsManagementRoutePresentation> get managementRows => const [
    SettingsManagementRoutePresentation(
      keyValue: 'settings-manage-gateways',
      title: 'Manage gateways',
      subtitle: 'Add, test, edit, and remove Gormes gateway connections.',
      route: AppRoutes.servers,
    ),
    SettingsManagementRoutePresentation(
      keyValue: 'settings-manage-profiles',
      title: 'Manage profile contacts',
      subtitle:
          'Create, refresh, edit, or select profiles from the Agents tab.',
      route: AppRoutes.agents,
    ),
  ];

  String get continuousVoiceTitle => 'Continuous voice';

  String get continuousVoiceSubtitle =>
      'Use local device STT for the active profile';

  String get commandWordTitle => 'Command word';

  String get profileSwitchingTitle => 'Voice profile switching';

  String get profileSwitchingSubtitle =>
      'Allow local command-word profile switches';

  SettingsManagementOverviewPresentation managementOverview({
    required int serverCount,
    required int profileContactCount,
  }) {
    return SettingsManagementOverviewPresentation(
      keyValue: 'settings-management-overview',
      title: 'Management overview',
      subtitle:
          '${_countLabel(serverCount, 'Gormes gateway')} · ${_countLabel(profileContactCount, 'profile contact')}',
    );
  }

  SettingsTrustRowPresentation trustRowFor(
    NavivoxServer server, {
    required NavivoxVoiceSettings settings,
  }) {
    return SettingsTrustRowPresentation(
      keyValue: 'voice-trust-${server.id}',
      title: 'Trust ${server.name} for voice',
      subtitle: 'Local-only trust, not server config',
      trusted: settings.isTrusted(server.id),
    );
  }

  SettingsCurrentScopePresentation? currentScopeFor({
    required NavivoxServer? activeServer,
    required NavivoxProfileContact? activeProfile,
  }) {
    if (activeServer == null && activeProfile == null) return null;
    return SettingsCurrentScopePresentation(
      title: 'Current session scope',
      subtitle:
          'Local settings apply to the currently selected gateway and profile contact.',
      gateway: activeServer == null
          ? null
          : SettingsScopeRowPresentation(
              keyValue: 'settings-current-gateway',
              title: 'Active Gormes gateway',
              subtitle:
                  '${activeServer.name} · ${activeServer.id} · ${activeServer.status}',
            ),
      profile: activeProfile == null
          ? null
          : SettingsScopeRowPresentation(
              keyValue: 'settings-current-profile',
              title: 'Active profile contact',
              subtitle:
                  '${activeProfile.displayName} · ${activeProfile.serverId}/${activeProfile.profileId} · ${healthLabel(activeProfile.health)}',
            ),
    );
  }

  String healthLabel(NavivoxProfileHealth health) {
    return switch (health) {
      NavivoxProfileHealth.online => 'online',
      NavivoxProfileHealth.offline => 'offline',
      NavivoxProfileHealth.needsAuth => 'auth',
      NavivoxProfileHealth.warning => 'warning',
    };
  }

  String _countLabel(int count, String singular) {
    final plural = count == 1 ? singular : '${singular}s';
    return '$count $plural';
  }
}

class SettingsManagementRoutePresentation {
  const SettingsManagementRoutePresentation({
    required this.keyValue,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String keyValue;
  final String title;
  final String subtitle;
  final String route;
}

class SettingsManagementOverviewPresentation {
  const SettingsManagementOverviewPresentation({
    required this.keyValue,
    required this.title,
    required this.subtitle,
  });

  final String keyValue;
  final String title;
  final String subtitle;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsManagementOverviewPresentation &&
            other.keyValue == keyValue &&
            other.title == title &&
            other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(keyValue, title, subtitle);
}

class SettingsTrustRowPresentation {
  const SettingsTrustRowPresentation({
    required this.keyValue,
    required this.title,
    required this.subtitle,
    required this.trusted,
  });

  final String keyValue;
  final String title;
  final String subtitle;
  final bool trusted;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsTrustRowPresentation &&
            other.keyValue == keyValue &&
            other.title == title &&
            other.subtitle == subtitle &&
            other.trusted == trusted;
  }

  @override
  int get hashCode => Object.hash(keyValue, title, subtitle, trusted);
}

class SettingsCurrentScopePresentation {
  const SettingsCurrentScopePresentation({
    required this.title,
    required this.subtitle,
    this.gateway,
    this.profile,
  });

  final String title;
  final String subtitle;
  final SettingsScopeRowPresentation? gateway;
  final SettingsScopeRowPresentation? profile;
}

class SettingsScopeRowPresentation {
  const SettingsScopeRowPresentation({
    required this.keyValue,
    required this.title,
    required this.subtitle,
  });

  final String keyValue;
  final String title;
  final String subtitle;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsScopeRowPresentation &&
            other.keyValue == keyValue &&
            other.title == title &&
            other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(keyValue, title, subtitle);
}
