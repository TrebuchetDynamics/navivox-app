import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';

void main() {
  group('gateway bearer auth parsing', () {
    test('accepts auth scheme casing used by HTTP clients', () {
      expect(
        navivoxGatewayBearerToken({'authorization': 'bearer nvbx:test'}),
        'nvbx:test',
      );
      expect(
        navivoxGatewayWebSocketProtocols({'authorization': 'bearer nvbx:test'}),
        [
          navivoxWebSocketProtocol,
          '${navivoxWebSocketTokenProtocolPrefix}bnZieDp0ZXN0',
        ],
      );
    });

    test('rejects ambiguous case-variant auth header maps', () {
      final headers = {
        'Authorization': 'Bearer good-token',
        'authorization': 'Bearer other-token',
      };

      expect(navivoxGatewayBearerToken(headers), isNull);
      expect(navivoxGatewayWebSocketProtocols(headers), [
        navivoxWebSocketProtocol,
      ]);
    });
  });
}
