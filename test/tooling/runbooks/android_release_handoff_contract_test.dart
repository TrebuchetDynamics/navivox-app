import 'package:flutter_test/flutter_test.dart';

import '../shared/file_contract_helpers.dart';

void main() {
  test('Android release handoff documents safe local install artifacts', () {
    final text = readRequiredFiles([
      'docs/runbooks/android/release-handoff.md',
      'docs/runbooks/shared/android-device-and-secret-contracts.md',
    ]);

    expect(text, contains('# Android Release Handoff'));
    expect(text, contains('flutter build apk --debug'));
    expect(text, contains('build/app/outputs/flutter-apk/app-debug.apk'));
    expect(text, contains('flutter install -d <device-id>'));
    expect(text, contains('adb install -r'));
    expect(text, contains('flutter build appbundle --release'));
    expect(text, contains('build/app/outputs/bundle/release/app-release.aab'));
    expect(text, contains('pairing secrets contract'));
    expect(text, contains('Do not paste tokens'));
    expect(text, contains('trusted tester'));
    expect(text, contains('## Continuous voice smoke after install'));
    expect(
      text,
      contains(
        'adb shell cmd package query-services -a android.speech.RecognitionService',
      ),
    );
    expect(text, contains('microphone permission'));
    expect(text, contains('Continuous voice ready'));
    expect(text, contains('## Continuous voice blocker handoff'));
    expect(text, contains('Run id: `voice-readiness-smoke-2026-05-27`'));
    expect(text, contains('Latest local debug APK'));
    expect(text, contains('sha256 af9ba1fb0b16efc9bb9b31d8e2684dc191f00781e378a2850e4e25cf3b64c8dc'));
    expect(text, contains('flutter devices` lists only Linux desktop and Chrome'));
    expect(text, contains('/dev/kvm'));
    expect(
      text,
      contains(
        'Android recognizer, microphone permission, and gateway profile STT are separate checks',
      ),
    );
    expect(text, contains('physical USB-debuggable Android device'));
    expectNoSecretPlaceholders(text);
  });
}
