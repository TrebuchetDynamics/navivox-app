import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('README documents MIT license and real app screenshots', () {
    final readme = File('../README.md').readAsStringSync();
    final license = File('../LICENSE').readAsStringSync();

    expect(readme, contains('## Screenshots'));
    expect(readme, contains('![Setup screen](docs/screenshots/setup.png)'));
    expect(readme, contains('![Chat screen](docs/screenshots/chat.png)'));
    expect(readme, contains('MIT License'));
    expect(readme, contains('See [LICENSE](LICENSE).'));

    expect(license, contains('MIT License'));
    expect(license, contains('Copyright (c) 2026 Trebuchet Dynamics'));

    for (final path in [
      '../docs/screenshots/setup.png',
      '../docs/screenshots/chat.png',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path should exist');
      final bytes = file.readAsBytesSync();
      expect(bytes.take(8), [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
      expect(
        bytes.length,
        greaterThan(4 * 1024),
        reason: '$path should be a real screenshot, not a placeholder',
      );
    }
  });
}
