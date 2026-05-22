import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Termux Gormes bootstrap guide documents safe Android phases', () {
    final guide = File('docs/termux-gormes-bootstrap.md');

    expect(guide.existsSync(), isTrue);

    final text = guide.readAsStringSync();
    final readme = File('README.md').readAsStringSync();

    expect(text, contains('# Termux Gormes Bootstrap'));
    expect(text, contains('Phase 1'));
    expect(text, contains('Phase 2'));
    expect(text, contains('Android >= 7'));
    expect(text, contains('F-Droid'));
    expect(text, contains('GitHub Releases'));
    expect(text, contains('Google Play'));
    expect(text, contains('do not mix Termux APK sources'));
    expect(text, contains('pkg upgrade'));
    expect(text, contains('pkg install git curl'));
    expect(text, contains('termux-setup-storage'));
    expect(text, contains('install.sh'));
    expect(text, contains('bash install.sh'));
    expect(text, contains('Navivox cannot silently install Gormes'));
    expect(text, contains('gormes navivox connect-info'));
    expect(text, contains('Never paste pairing tokens'));
    expect(text, isNot(contains('curl | sh')));
    expect(text, isNot(contains('nvbx_')));
    expect(readme, contains('docs/termux-gormes-bootstrap.md'));
  });
}
