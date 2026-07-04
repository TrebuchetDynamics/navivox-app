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
    expect(debugEntitlements, contains('com.apple.security.network.client'));
    expect(releaseEntitlements, contains('com.apple.security.network.client'));
  });
}
