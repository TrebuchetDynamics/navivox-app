import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/persistence/session_staleness.dart';

void main() {
  group('isSavedSessionStale', () {
    final now = DateTime.utc(2026, 5, 31, 12);

    test('treats missing last connection as stale', () {
      expect(isSavedSessionStale(lastConnectedAt: null, now: now), isTrue);
    });

    test(
      'uses the full stale duration instead of truncating to calendar days',
      () {
        expect(
          isSavedSessionStale(
            lastConnectedAt: now.subtract(const Duration(days: 7, hours: 1)),
            now: now,
          ),
          isTrue,
        );
      },
    );

    test('keeps sessions fresh until the stale duration elapses', () {
      expect(
        isSavedSessionStale(
          lastConnectedAt: now.subtract(const Duration(days: 7)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
