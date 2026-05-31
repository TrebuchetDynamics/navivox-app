import 'package:flutter_test/flutter_test.dart';

void expectTranscriptDisplayText({
  required String actualText,
  required bool actualIsVisible,
  required String expectedText,
  String? reason,
}) {
  expect(actualText, expectedText, reason: reason);
  expect(actualIsVisible, expectedText.isNotEmpty, reason: reason);
}
