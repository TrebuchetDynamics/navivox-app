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
    expect(text, contains('GORMES_SKIP_SETUP=1 bash install.sh'));
    expect(
      text,
      contains('(gormes navivox pair || gormes navivox connect-info)'),
    );
    expect(text, contains('Navivox cannot silently install Gormes'));
    expect(text, contains('gormes navivox connect-info'));
    expect(text, contains('Never paste pairing tokens'));
    expect(text, contains('one terminal interaction maximum'));
    expect(
      text,
      contains('Install Termux, paste one command, continue in Navivox'),
    );
    expect(text, contains('Gormes installed successfully'));
    expect(text, contains('Navivox (recommended)'));
    expect(text, contains('CLI setup'));
    expect(text, contains('gormes navivox pair'));
    expect(text, contains('start local bridge'));
    expect(text, contains('generate a pairing token'));
    expect(text, contains('show a QR'));
    expect(text, contains('print localhost URL'));
    expect(text, contains('wait for Navivox connection'));
    expect(text, contains('Termux:Boot'));
    expect(text, contains('same APK source'));
    expect(text, contains('gormes gateway boot-install'));
    expect(text, contains('gormes gateway boot-uninstall'));
    expect(text, contains('.termux/boot/gormes-gateway.sh'));
    expect(text, isNot(contains('curl | sh')));
    expect(text, isNot(contains('pm install')));
    expect(text, isNot(contains('nvbx_')));
    expect(readme, contains('docs/termux-gormes-bootstrap.md'));
  });
}
