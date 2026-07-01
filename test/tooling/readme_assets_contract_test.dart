import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('README documents root-level install flow and real app screenshots', () {
    expect(File('CONTEXT.md').existsSync(), isTrue);
    expect(File('pubspec.yaml').existsSync(), isTrue);
    expect(File('lib/main.dart').existsSync(), isTrue);
    expect(
      Directory('app').existsSync(),
      isFalse,
      reason: 'Navivox should be a root-level Flutter package, not app/.',
    );

    final readme = File('README.md').readAsStringSync();
    final license = File('LICENSE').readAsStringSync();

    expect(readme, contains('## Install And Run'));
    expect(readme, contains('flutter pub get'));
    expect(readme, contains('flutter analyze'));
    expect(readme, contains('flutter test'));
    expect(readme, contains('flutter devices'));
    expect(readme, contains('flutter run -d <device-id>'));
    expect(readme, contains('Android emulator'));
    expect(readme, contains('10.0.2.2'));
    expect(readme, contains('physical Android device'));
    expect(readme, contains('Hermes endpoint URL hints'));
    expect(readme, contains('http://127.0.0.1:8642'));
    expect(readme, contains('http://10.0.2.2:8642'));
    expect(readme, contains('## Connected Hermes Smoke Test'));
    expect(readme, contains('GET /health'));
    expect(readme, contains('GET /v1/capabilities'));
    expect(readme, contains('POST /api/sessions/{session_id}/chat/stream'));
    expect(readme, contains('docs/runbooks/termux/gormes-bootstrap.md'));
    expect(
      readme,
      contains('Do not expose API keys, pairing tokens, raw tool payloads'),
    );
    expect(readme, contains('## Troubleshooting'));
    expect(readme, contains('flutter doctor'));
    expect(readme, contains('No supported devices found'));
    expect(readme, contains('libsecret-1'));
    expect(readme, contains('`401` or `403`'));
    expect(readme, contains('API key'));
    expect(readme, isNot(contains('cd app')));
    expect(readme, contains('## Screenshots'));
    expect(readme, contains('![Setup screen](docs/screenshots/setup.png)'));
    expect(readme, contains('![Chat screen](docs/screenshots/chat.png)'));
    expect(readme, contains('MIT License'));
    expect(readme, contains('See [LICENSE](LICENSE).'));

    expect(license, contains('MIT License'));
    expect(license, contains('Copyright (c) 2026 Trebuchet Dynamics'));

    for (final path in [
      'docs/screenshots/setup.png',
      'docs/screenshots/chat.png',
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
