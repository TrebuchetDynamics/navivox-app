import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/router/app_routes.dart';

void main() {
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

  test('recognizes setup and chat thread locations', () {
    expect(AppRoutes.isSetupLocation('/setup'), isTrue);
    expect(AppRoutes.isSetupLocation('/setup/import'), isTrue);
    expect(AppRoutes.isSetupLocation('/settings'), isFalse);

    expect(
      AppRoutes.isChatThreadLocation('/chats/office%20team/support%2Fdesk'),
      isTrue,
    );
    expect(AppRoutes.isChatThreadLocation('/chats'), isFalse);
    expect(AppRoutes.isChatThreadLocation('/servers'), isFalse);
  });
}
