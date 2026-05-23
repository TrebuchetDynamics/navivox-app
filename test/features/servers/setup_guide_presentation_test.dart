import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/setup_guide_presentation.dart';

void main() {
  const presentation = SetupGuidePresentation();

  test('exposes ordered Termux setup guide copy actions', () {
    expect(
      presentation.introCopy,
      contains('Run Gormes on this Android device with Termux'),
    );
    expect(presentation.introCopy, contains('Navivox (recommended)'));
    expect(presentation.introCopy, contains('connect-info fallback'));

    expect(presentation.entries.map((entry) => entry.id).toList(), const [
      SetupGuideEntryId.bootstrap,
      SetupGuideEntryId.downloadLinks,
      SetupGuideEntryId.postInstallChecks,
      SetupGuideEntryId.navivoxPairHandoff,
      SetupGuideEntryId.gatewayLifecycle,
      SetupGuideEntryId.bootHelper,
      SetupGuideEntryId.connectionHint,
      SetupGuideEntryId.storageCommand,
    ]);
    expect(presentation.entries.map((entry) => entry.label).toList(), const [
      'Copy one-paste bootstrap',
      'Copy Termux download links',
      'Copy post-install checks',
      'Copy Navivox pair handoff',
      'Copy Termux gateway lifecycle',
      'Copy Termux:Boot helper',
      'Copy same-device connection hint',
      'Copy optional storage command',
    ]);
  });

  test('keeps clipboard payloads safe and statused', () {
    for (final entry in presentation.entries) {
      expect(entry.clipboardText, isNotEmpty, reason: entry.label);
      expect(entry.successMessage, startsWith('Copied'), reason: entry.label);
      expect(
        entry.failureMessage,
        startsWith('Could not copy'),
        reason: entry.label,
      );
      expect(
        entry.clipboardText.toLowerCase(),
        isNot(contains('nvbx_')),
        reason: entry.label,
      );
    }

    final bootstrap = presentation.entry(SetupGuideEntryId.bootstrap);
    expect(bootstrap.clipboardText, contains('one pasted Termux command'));
    expect(bootstrap.clipboardText, contains('less install.sh'));
    expect(
      bootstrap.clipboardText,
      contains('GORMES_SKIP_SETUP=1 bash install.sh'),
    );
    expect(bootstrap.clipboardText.toLowerCase(), isNot(contains('curl | sh')));

    final downloadLinks = presentation.entry(SetupGuideEntryId.downloadLinks);
    expect(downloadLinks.clipboardText, contains('https://termux.dev/en/'));
    expect(
      downloadLinks.clipboardText,
      contains('https://f-droid.org/packages/com.termux/'),
    );
    expect(
      downloadLinks.clipboardText.toLowerCase(),
      isNot(contains('play.google')),
    );

    final connectionHint = presentation.entry(SetupGuideEntryId.connectionHint);
    expect(connectionHint.clipboardText, contains('http://127.0.0.1:<port>'));
    expect(connectionHint.clipboardText, contains('http://10.0.2.2:<port>'));
    expect(connectionHint.clipboardText, contains('LAN, VPN, or Tailscale'));
  });

  test('owns setup guide copy success and failure messages', () {
    expect(
      presentation.entries.map((entry) => entry.successMessage).toList(),
      const [
        'Copied one-paste Termux bootstrap.',
        'Copied Termux download links.',
        'Copied post-install Termux checks.',
        'Copied Navivox pair handoff.',
        'Copied Termux gateway lifecycle.',
        'Copied Termux:Boot helper.',
        'Copied same-device connection hint.',
        'Copied optional Termux storage command.',
      ],
    );
    expect(
      presentation.entries.map((entry) => entry.failureMessage).toList(),
      const [
        'Could not copy one-paste bootstrap.',
        'Could not copy Termux download links.',
        'Could not copy post-install checks.',
        'Could not copy Navivox pair handoff.',
        'Could not copy gateway lifecycle.',
        'Could not copy Termux:Boot helper.',
        'Could not copy connection hint.',
        'Could not copy storage command.',
      ],
    );
  });
}
