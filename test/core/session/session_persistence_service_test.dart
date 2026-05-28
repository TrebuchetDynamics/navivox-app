import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:navivox/core/session/session_persistence_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionPersistenceService', () {
    test('saves and loads non-secret gateway metadata', () async {
      final service = SessionPersistenceService();
      await service.saveConnection(
        baseUrl: 'http://192.168.1.100:8765',
        webSocketUrl: 'ws://192.168.1.100:8765/v1/navivox/stream',
        gatewayId: 'gw-abc-123',
      );

      final session = await service.loadSession();
      expect(session, isNotNull);
      expect(session!.baseUrl, 'http://192.168.1.100:8765');
      expect(session.webSocketUrl, 'ws://192.168.1.100:8765/v1/navivox/stream');
      expect(session.gatewayId, 'gw-abc-123');
      expect(session.lastConnectedAt, isNotNull);
      expect(session.canAttemptReconnect, isFalse);
      expect(session.isStale, isFalse);
    });

    test('loadSession returns null when no session saved', () async {
      final service = SessionPersistenceService();
      final session = await service.loadSession();
      expect(session, isNull);
    });

    test('clearSession removes all saved data', () async {
      final service = SessionPersistenceService();
      await service.saveConnection(baseUrl: 'http://localhost:8765');
      expect(await service.hasSession(), isTrue);

      await service.clearSession();
      expect(await service.loadSession(), isNull);
      expect(await service.hasSession(), isFalse);
    });

    test('saveConnection without optional fields', () async {
      final service = SessionPersistenceService();
      await service.saveConnection(baseUrl: 'http://localhost:8765');

      final session = await service.loadSession();
      expect(session, isNotNull);
      expect(session!.baseUrl, 'http://localhost:8765');
      expect(session.webSocketUrl, isNull);
      expect(session.gatewayId, isNull);
      expect(session.canAttemptReconnect, isFalse);
    });

    test('isStale detects old sessions', () async {
      SharedPreferences.setMockInitialValues({
        'navivox.session.base_url': 'http://localhost:8765',
        'navivox.session.last_connected_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
      });

      final service = SessionPersistenceService();
      final session = await service.loadSession();
      expect(session, isNotNull);
      expect(session!.isStale, isTrue);
    });

    test('does not persist pairing tokens or QR payloads', () async {
      SharedPreferences.setMockInitialValues({
        'navivox.session.token': 'nvbx_legacy_token',
      });
      final service = SessionPersistenceService();
      await service.saveConnection(baseUrl: 'http://192.168.1.100:8765');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('navivox.session.token'), isNull);
      for (final key in prefs.getKeys()) {
        final value = prefs.getString(key);
        if (value != null) {
          expect(
            value.contains('nvbx_'),
            isFalse,
            reason: 'token leaked into $key',
          );
          expect(
            value.contains('navivox://connect'),
            isFalse,
            reason: 'QR descriptor leaked into $key',
          );
        }
      }
    });
  });
}
