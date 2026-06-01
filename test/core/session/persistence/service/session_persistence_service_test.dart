import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:navivox/core/session/session_persistence_service.dart';
import 'package:navivox/core/session/persistence/storage/session_preference_keys.dart';

import '../../support/session_persistence_test_support.dart';
import '../support/session_persistence_expectations.dart';

void main() {
  setUp(() {
    resetSessionPreferences();
  });

  group('SessionPersistenceService', () {
    test('saves and loads non-secret gateway metadata', () async {
      final service = SessionPersistenceService();
      await saveLocalGatewayConnection(service);

      final session = await service.loadSession();
      expect(session, isNotNull);
      expectLocalGatewaySession(session!);
      expect(session.isStale, isFalse);
    });

    test('loadSession returns null when no session saved', () async {
      final service = SessionPersistenceService();
      await expectNoSavedSession(service);
    });

    test('clearSession removes all saved data', () async {
      final service = SessionPersistenceService();
      await service.saveConnection(baseUrl: 'http://localhost:8765');
      expect(await service.hasSession(), isTrue);

      await service.clearSession();
      await expectNoSavedSession(service);
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

    test(
      'saveConnection rejects blank base URL without touching prefs',
      () async {
        resetSessionPreferences({
          SessionPreferenceKeys.baseUrl: localGatewayBaseUrl,
          SessionPreferenceKeys.webSocketUrl: localGatewayWebSocketUrl,
          SessionPreferenceKeys.gatewayId: localGatewayId,
        });
        final service = SessionPersistenceService();

        await expectLater(
          service.saveConnection(baseUrl: '   '),
          throwsA(isA<ArgumentError>()),
        );

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(SessionPreferenceKeys.baseUrl),
          localGatewayBaseUrl,
        );
        expect(
          prefs.getString(SessionPreferenceKeys.webSocketUrl),
          localGatewayWebSocketUrl,
        );
        expect(
          prefs.getString(SessionPreferenceKeys.gatewayId),
          localGatewayId,
        );
      },
    );

    test('isStale detects old sessions', () async {
      resetSessionPreferences({
        SessionPreferenceKeys.baseUrl: 'http://localhost:8765',
        SessionPreferenceKeys.lastConnectedAt: DateTime.now()
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
      resetSessionPreferences({
        SessionPreferenceKeys.legacyToken: 'nvbx_legacy_token',
      });
      final service = SessionPersistenceService();
      await service.saveConnection(baseUrl: localGatewayBaseUrl);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SessionPreferenceKeys.legacyToken), isNull);
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
