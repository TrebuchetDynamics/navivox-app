import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS scaffold declares voice permission copy for Hermes voice input',
    () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(plist, contains('NSMicrophoneUsageDescription'));
      expect(plist, contains('NSSpeechRecognitionUsageDescription'));
      expect(plist, contains('Hermes Agent'));
    },
  );

  test('web scaffold uses the device viewport on mobile browsers', () {
    final html = File('web/index.html').readAsStringSync();

    expect(
      html,
      contains(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
      ),
    );
  });

  test('Windows scaffold is present for host-runner validation', () {
    expect(File('windows/CMakeLists.txt').existsSync(), isTrue);
    expect(File('windows/runner/main.cpp').existsSync(), isTrue);
    expect(
      File('windows/flutter/generated_plugins.cmake').existsSync(),
      isTrue,
    );
  });

  test('macOS scaffold is present for host-runner validation', () {
    expect(File('macos/Runner.xcodeproj/project.pbxproj').existsSync(), isTrue);
    expect(File('macos/Runner/AppDelegate.swift').existsSync(), isTrue);
    final debugEntitlements = File(
      'macos/Runner/DebugProfile.entitlements',
    ).readAsStringSync();
    final releaseEntitlements = File(
      'macos/Runner/Release.entitlements',
    ).readAsStringSync();
    final plist = File('macos/Runner/Info.plist').readAsStringSync();
    expect(debugEntitlements, contains('com.apple.security.network.client'));
    expect(releaseEntitlements, contains('com.apple.security.network.client'));
    expect(
      debugEntitlements,
      contains('com.apple.security.device.audio-input'),
    );
    expect(
      releaseEntitlements,
      contains('com.apple.security.device.audio-input'),
    );
    expect(plist, contains('NSMicrophoneUsageDescription'));
    expect(plist, contains('NSSpeechRecognitionUsageDescription'));
  });

  test('Android scaffold supports microphone and Bluetooth headsets', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android.permission.RECORD_AUDIO'));
    expect(manifest, contains('android.permission.BLUETOOTH_CONNECT'));
    expect(manifest, contains('android.speech.RecognitionService'));
  });
}
