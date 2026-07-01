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
}
