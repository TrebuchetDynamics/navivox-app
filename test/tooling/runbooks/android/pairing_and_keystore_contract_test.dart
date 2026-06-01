import 'package:flutter_test/flutter_test.dart';

import '../shared/runbook_contract_helpers.dart';

void main() {
  test('Android pairing handoff smoke keeps intent commands and token safety', () {
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
  });

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

  test('Android durable keystore smoke keeps reconnect secret boundaries', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/android/durable-keystore-smoke.md',
    );

    expectRunbookContainsAll(text, [
      '# Android Durable Keystore Smoke',
      'durable reconnect key storage',
      'trusted Android device',
      'durable reconnect',
      'non-secret public key',
      'no pairing token is stored',
      'reconnect readiness remains available',
      'Do not paste tokens',
    ]);
    expectRunbookHasNoSecretPlaceholders(text);
  });
}
