import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_detached_run_store.dart';

void main() {
  test('detached run lease round trips only opaque reconciliation fields', () {
    final lease = HermesDetachedRunLease(
      runId: 'run_1',
      sessionId: 'session_1',
      baseUrl: 'https://gateway.example',
      profileId: 'coder',
      createdAt: DateTime.utc(2026, 7, 18, 12),
    );

    final json = lease.toJson();
    expect(json, {
      'run_id': 'run_1',
      'session_id': 'session_1',
      'base_url': 'https://gateway.example',
      'profile_id': 'coder',
      'created_at': '2026-07-18T12:00:00.000Z',
    });
    expect(json.keys, isNot(containsAll(['prompt', 'output', 'api_key'])));

    final restored = HermesDetachedRunLease.fromJson(json);
    expect(restored.runId, lease.runId);
    expect(restored.sessionId, lease.sessionId);
    expect(restored.baseUrl, lease.baseUrl);
    expect(restored.profileId, lease.profileId);
    expect(restored.createdAt, lease.createdAt);
  });

  test('detached run lease rejects blank or oversized handles', () {
    expect(
      () => HermesDetachedRunLease.fromJson({
        'run_id': '',
        'session_id': 'session_1',
        'base_url': 'https://gateway.example',
        'created_at': '2026-07-18T12:00:00Z',
      }),
      throwsFormatException,
    );
    expect(
      () => HermesDetachedRunLease.fromJson({
        'run_id': 'r' * 257,
        'session_id': 'session_1',
        'base_url': 'https://gateway.example',
        'created_at': '2026-07-18T12:00:00Z',
      }),
      throwsFormatException,
    );
  });
}
