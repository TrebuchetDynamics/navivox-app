import 'package:flutter_test/flutter_test.dart';

import '../shared/runbook_contract_helpers.dart';

void main() {
  test(
    'Android pairing handoff smoke keeps intent commands and token safety',
    () {
      final text = readRunbookContractWithSharedPolicy(
        'docs/runbooks/android/pairing-handoff-smoke.md',
      );

      expectRunbookContainsAll(text, [
        '# Android Pairing Handoff Smoke',
        'Manual smoke for the Android platform seam',
        'android.intent.action.VIEW',
        'android.intent.action.SEND',
        'android.intent.extra.TEXT',
        'navivox://connect?base_url=',
        'direct app-open source',
        'shared-text source',
        'shared text must not auto-connect',
        'UI and diagnostics must not display the token value',
        'Do not paste tokens',
      ]);
      expectRunbookHasNoSecretPlaceholders(text);
    },
  );

  test('Android pairing instrumentation points to canonical manual smoke', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/android/pairing-handoff-instrumentation.md',
    );

    expectRunbookContainsAll(text, [
      '# Optional Android Pairing Handoff Instrumentation Smoke',
      'flutter test integration_test/android_pairing_handoff_smoke_test.dart -d <android-device-id>',
      'ci-secret-token-do-not-render',
      'token leak',
      'docs/runbooks/android/pairing-handoff-smoke.md',
      'Do not paste tokens',
    ]);
    expectRunbookOmitsAll(text, [
      'docs/runbooks/android-pairing-handoff-smoke.md',
    ]);
    expectRunbookHasNoSecretPlaceholders(text);
  });

  test('Android durable keystore smoke is marked legacy-only', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/android/durable-keystore-smoke.md',
    );

    expectRunbookContainsAll(text, [
      '# Android Durable Keystore Smoke (legacy)',
      'not** part of the active\npure-Hermes Navivox readiness gate',
      'npm run android:durable-key-smoke',
      'integration_test/durable_key_store_android_smoke_test.dart',
      'legacy key storage readiness only',
      'does **not** prove active Hermes\nchat, voice, provider, platform, or realtime/server-audio readiness',
      'not a blocker for the pure-Hermes companion goal',
      'NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit',
      'Completion verdict: NOT COMPLETE',
      'do not promote this legacy key smoke',
      'passing tests, APK hashes, configured Hermes home, workflow YAML, or\ndispatch-only output to whole-goal completion',
      'Do not paste tokens',
    ]);
    expectRunbookHasNoSecretPlaceholders(text);
  });
}
