import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/persistence/contracts/saved_session_fields.dart';

void main() {
  group('SavedSessionFields.fromStoredValues', () {
    test('rejects missing or blank base URL as no saved session', () {
      expect(SavedSessionFields.fromStoredValues(baseUrl: null), isNull);
      expect(SavedSessionFields.fromStoredValues(baseUrl: '   '), isNull);
    });

    test('normalizes optional metadata without dropping a valid session', () {
      final fields = SavedSessionFields.fromStoredValues(
        baseUrl: ' http://localhost:8765 ',
        webSocketUrl: '   ',
        gatewayId: ' gateway-local ',
        lastConnectedAt: '2026-05-31T12:00:00Z',
      );

      expect(fields, isNotNull);
      expect(fields!.baseUrl, 'http://localhost:8765');
      expect(fields.webSocketUrl, isNull);
      expect(fields.gatewayId, 'gateway-local');
      expect(fields.lastConnectedAt, DateTime.utc(2026, 5, 31, 12));
    });

    test('keeps invalid timestamps visible as missing staleness data', () {
      final fields = SavedSessionFields.fromStoredValues(
        baseUrl: 'http://localhost:8765',
        lastConnectedAt: 'not a date',
      );

      expect(fields, isNotNull);
      expect(fields!.lastConnectedAt, isNull);
    });
  });
}
