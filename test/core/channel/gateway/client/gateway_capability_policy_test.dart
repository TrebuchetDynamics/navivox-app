import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway/client/gateway_capability_policy.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';

import '../../support/gateway_routing_test_support.dart';

void main() {
  test('capability policy rejects identity-header-only auth documents', () {
    final payload = gatewayRoutingCapabilityDocument();
    payload['auth'] = {
      'mode': 'tailscale_identity',
      'headers': ['Tailscale-User-Login'],
      'websocket_protocols': ['navivox.v1'],
    };

    final capabilities = NavivoxCapabilityDocument.fromJson(payload);

    expect(navivoxCapabilityDocumentUsable(capabilities), isFalse);
  });

  test('capability policy accepts token-bound auth documents', () {
    final capabilities = NavivoxCapabilityDocument.fromJson(
      gatewayRoutingCapabilityDocument(),
    );

    expect(navivoxCapabilityDocumentUsable(capabilities), isTrue);
  });
}
