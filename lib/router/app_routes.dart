abstract final class AppRoutes {
  static const setup = '/setup';
  static const chats = '/chats';
  static const chatThread = '/chats/:serverId/:profileId';
  static const servers = '/servers';
  static const memory = '/memory';
  static const agents = '/agents';
  static const config = '/config';
  static const configSection = '/config/:section';
  static const settings = '/settings';

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
    return location == setup || location.startsWith('$setup/');
  }

  static bool isChatThreadLocation(String location) {
    return location.startsWith('$chats/');
  }
}
