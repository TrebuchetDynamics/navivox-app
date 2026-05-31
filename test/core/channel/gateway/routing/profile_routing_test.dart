import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway_navivox_channel.dart';

import '../support/profile_gateway_test_server.dart';

void main() {
  test(
    'connect loads Gormes profile routing choices when advertised',
    () async {
      final server = await ProfileGatewayTestServer.start();
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

      expect(channel.state.profileRouting.profiles, hasLength(1));
      final route = channel.state.profileRouting.profiles.single;
      expect(route.profileId, 'mineru');
      expect(route.displayName, 'Mineru Ops');
      expect(route.workspaces, ['/srv/gormes', '/srv/navivox']);
      expect(route.providers, ['openai-codex', 'ollama']);
      expect(route.channels, ['navivox', 'telegram']);
      expect(channel.state.activeProfileRoute?.profileId, 'mineru');
    },
  );
}
