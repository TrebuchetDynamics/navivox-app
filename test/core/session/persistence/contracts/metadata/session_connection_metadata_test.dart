import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/persistence/contracts/metadata/connection/session_connection_metadata.dart';

void main() {
  group('sanitizedSavedSessionWebSocketUrl', () {
    test('strips non-durable authority/query/fragment secret material', () {
      expect(
        sanitizedSavedSessionWebSocketUrl(
          'wss://pairing-token@gateway.example:9443/v1/navivox/stream?token=nvbx_pairing_token#handoff',
        ),
        'wss://gateway.example:9443/v1/navivox/stream',
      );
    });

    test('keeps non-websocket legacy values trimmed for compatibility', () {
      expect(
        sanitizedSavedSessionWebSocketUrl('  https://gateway.example/stream  '),
        'https://gateway.example/stream',
      );
    });
  });
}
