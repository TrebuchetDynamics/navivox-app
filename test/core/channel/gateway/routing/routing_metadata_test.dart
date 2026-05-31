import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway_navivox_channel.dart';

import '../support/profile_gateway_test_server.dart';

void main() {
  test('selected profile routing is included in start turn metadata', () async {
    final server = await ProfileGatewayTestServer.start(
      captureStreamMessages: true,
    );
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);
    channel.selectProfileRouting(
      workspace: '/srv/navivox',
      provider: 'ollama',
      channel: 'telegram',
    );

    channel.sendText('use the selected route');

    final sent = await server.nextClientMessage;
    final metadata = Map<String, Object?>.from(sent['metadata'] as Map);
    expect(metadata['server_id'], 'local-gormes');
    expect(metadata['profile_id'], 'mineru');
    expect(metadata['workspace'], '/srv/navivox');
    expect(metadata['provider_id'], 'ollama');
    expect(metadata['channel_id'], 'telegram');
  });
}
