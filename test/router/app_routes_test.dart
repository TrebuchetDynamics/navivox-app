import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/router/app_routes.dart';

void main() {
  test('defines route patterns from shared parameter names', () {
    expect(AppRoutes.chatThread, '/chats/:serverId/:profileId');
    expect(AppRoutes.configSection, '/config/:section');
    expect(RouteParameters.serverId, 'serverId');
    expect(RouteParameters.profileId, 'profileId');
    expect(RouteParameters.configSection, 'section');
  });

  test('builds encoded Profile contact chat locations', () {
    expect(
      AppRoutes.chatLocation(
        serverId: 'office team',
        profileId: 'support/desk',
      ),
      '/chats/office%20team/support%2Fdesk',
    );
  });

  test('builds encoded config section locations', () {
    expect(
      AppRoutes.configSectionLocation('provider defaults'),
      '/config/provider%20defaults',
    );
  });

  test('recognizes setup and chat thread locations by path only', () {
    expect(AppRoutes.isSetupLocation('/setup'), isTrue);
    expect(AppRoutes.isSetupLocation('/setup/import'), isTrue);
    expect(AppRoutes.isSetupLocation('/setup?invite=abc#qr'), isTrue);
    expect(AppRoutes.isSetupLocation('/settings'), isFalse);

    expect(
      AppRoutes.isChatThreadLocation(
        '/chats/office%20team/support%2Fdesk?draft=1#composer',
      ),
      isTrue,
    );
    expect(AppRoutes.isChatThreadLocation('/chats'), isFalse);
    expect(AppRoutes.isChatThreadLocation('/chats/local'), isFalse);
    expect(
      AppRoutes.isChatThreadLocation('/chats/local/mineru/extra'),
      isFalse,
    );
    expect(AppRoutes.isChatThreadLocation('/servers'), isFalse);
  });

  test('recognizes navigation destinations by path only', () {
    expect(
      AppRoutes.isNavigationDestinationLocation(
        location: '/config?section=voice#capture',
        destinationPath: AppRoutes.config,
      ),
      isTrue,
    );
    expect(
      AppRoutes.isNavigationDestinationLocation(
        location: '/config/voice?advanced=true',
        destinationPath: AppRoutes.config,
      ),
      isTrue,
    );
    expect(
      AppRoutes.isNavigationDestinationLocation(
        location: '/configuration',
        destinationPath: AppRoutes.config,
      ),
      isFalse,
    );
  });
}
