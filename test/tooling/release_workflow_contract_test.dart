import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alpha artifacts require repository validation', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    expect(workflow, contains('  validation:\n'));
    expect(
      workflow,
      contains('dart format --output=none --set-exit-if-changed'),
    );
    expect(workflow, contains('flutter analyze'));
    expect(workflow, contains('flutter test --coverage --concurrency=1'));
    expect(workflow, contains('npm audit --audit-level=high'));
    expect(
      RegExp(r'  android:\n(?:.|\n)*?    needs: validation').hasMatch(workflow),
      isTrue,
    );
    expect(
      RegExp(r'  linux:\n(?:.|\n)*?    needs: validation').hasMatch(workflow),
      isTrue,
    );
  });
}
