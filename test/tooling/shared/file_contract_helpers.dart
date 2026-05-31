import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String readRequiredFile(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path should exist');
  return file.readAsStringSync();
}

String readRequiredFiles(Iterable<String> paths) {
  return paths.map(readRequiredFile).join('\n');
}

void expectNoSecretPlaceholders(String text) {
  expect(text, isNot(contains('nvbx_')));
}
