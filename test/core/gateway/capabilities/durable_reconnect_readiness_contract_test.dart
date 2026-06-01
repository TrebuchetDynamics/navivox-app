import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/capabilities/navivox_gateway_capabilities.dart';

void main() {
  test('available durable reconnect accepts known safe security contexts', () {
    for (final effectiveSecurity in const [
      'https',
      'loopback',
      'private_network',
      'private-network',
    ]) {
      final contract = DurableReconnectReadinessContract(
        supported: true,
        issueEndpoint: '/v1/navivox/device-credentials',
        authMethods: const ['device_key_challenge'],
        platforms: const ['android'],
        effectiveSecurity: effectiveSecurity,
        blockedReason: '',
      );

      expect(
        contract.kind,
        ReconnectReadinessKind.available,
        reason: effectiveSecurity,
      );
    }
  });

  test('blocks advertised reconnect on unknown effective security', () {
    final contract = DurableReconnectReadinessContract(
      supported: true,
      issueEndpoint: '/v1/navivox/device-credentials',
      authMethods: const ['device_key_challenge'],
      platforms: const ['android'],
      effectiveSecurity: 'public_internet',
      blockedReason: '',
    );

    expect(contract.kind, ReconnectReadinessKind.blocked);
    expect(
      contract.recoveryMessage,
      'Durable reconnect is advertised with unsupported effective security "public_internet".',
    );
  });
}
