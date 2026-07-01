import 'app_route_location_patterns.dart';

abstract final class RouteParameters {
  static const serverId = 'serverId';
  static const profileId = 'profileId';
  static const configSection = 'section';
}

abstract final class AppRoutes {
  static const setup = '/setup';
  static const chats = '/chats';
  static const chatThread =
      '/chats/:${RouteParameters.serverId}/:${RouteParameters.profileId}';
  static const servers = '/servers';
  static const memory = '/memory';
  static const agents = '/agents';
  static const config = '/config';
  static const configSection = '/config/:${RouteParameters.configSection}';
  static const settings = '/settings';

  /// Native Hermes Agent chat/session screen, additive alongside the Gormes
  /// screens above; see docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md.
  static const hermes = '/hermes';

  static String chatLocation({
    required String serverId,
    required String profileId,
  }) {
    return '$chats/${Uri.encodeComponent(serverId)}/'
        '${Uri.encodeComponent(profileId)}';
  }

  static String configSectionLocation(String sectionId) {
    return '$config/${Uri.encodeComponent(sectionId)}';
  }

  static bool isSetupLocation(String location) {
    return AppRouteLocationPattern.hasPathPrefix(
      location: location,
      pathPrefix: setup,
    );
  }

  static bool isChatThreadLocation(String location) {
    return AppRouteLocationPattern.hasExactPathSegments(
      location: location,
      expectedSegments: ['chats', '', ''],
    );
  }

  static bool isNavigationDestinationLocation({
    required String location,
    required String destinationPath,
  }) {
    return AppRouteLocationPattern.hasPathPrefix(
      location: location,
      pathPrefix: destinationPath,
    );
  }
}
