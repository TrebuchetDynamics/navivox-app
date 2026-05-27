import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/router/navigation_intent.dart';

void main() {
  final resolver = NavigationIntentResolver();

  group('NavigationIntentResolver', () {
    test('OpenAgents resolves to /agents', () {
      expect(resolver.resolve(const OpenAgents()), '/agents');
    });

    test('OpenWorkspace resolves to /memory', () {
      expect(resolver.resolve(const OpenWorkspace()), '/memory');
    });

    test('OpenConfig resolves to /config', () {
      expect(resolver.resolve(const OpenConfig()), '/config');
    });

    test('OpenSettings resolves to /settings', () {
      expect(resolver.resolve(const OpenSettings()), '/settings');
    });

    test('OpenGateways resolves to /servers', () {
      expect(resolver.resolve(const OpenGateways()), '/servers');
    });

    test('OpenChatsList resolves to /chats', () {
      expect(resolver.resolve(const OpenChatsList()), '/chats');
    });

    test('OpenChatThread resolves to encoded chat thread location', () {
      expect(
        resolver.resolve(const OpenChatThread('srv1', 'mineru')),
        '/chats/srv1/mineru',
      );
    });

    test('OpenChatThread encodes serverId and profileId', () {
      expect(
        resolver.resolve(const OpenChatThread('my server', 'my profile')),
        contains('/chats/'),
      );
      // Verify both IDs appear in the result
      final result = resolver.resolve(
        const OpenChatThread('a/b', 'c/d'),
      );
      expect(result, startsWith('/chats/'));
      expect(result, contains('a%2Fb'));
      expect(result, contains('c%2Fd'));
    });
  });
}