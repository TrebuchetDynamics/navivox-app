import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/persistence/session_staleness.dart';

void main() {
  group('isSavedSessionStale', () {
    final now = DateTime.utc(2026, 5, 31, 12);

    test('treats missing last connection as stale', () {
      expect(isSavedSessionStale(lastConnectedAt: null, now: now), isTrue);
    });

    test(
      'exposes the saved connection age for replayable staleness checks',
      () {
        expect(
          savedSessionConnectionAge(
            lastConnectedAt: now.subtract(const Duration(hours: 3)),
            now: now,
          ),
          const Duration(hours: 3),
        );
      },
    );

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

    test('treats future timestamps as stale instead of indefinitely fresh', () {
      expect(
        savedSessionConnectionAge(
          lastConnectedAt: now.add(const Duration(hours: 1)),
          now: now,
        ),
        const Duration(hours: -1),
      );
      expect(
        isSavedSessionStale(
          lastConnectedAt: now.add(const Duration(hours: 1)),
          now: now,
        ),
        isTrue,
      );
    });

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
