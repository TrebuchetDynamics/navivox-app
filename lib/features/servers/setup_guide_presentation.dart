class SetupGuidePresentation {
  const SetupGuidePresentation();

  String get introCopy =>
      'Same-device setup: install Termux from F-Droid or official GitHub '
      'Releases, paste the bootstrap command, then run `gormes navivox pair`. '
      'Navivox can open from the pairing link; QR/import and connect-info are '
      'fallbacks only.';

  List<SetupGuideEntry> get entries => _entries;

  List<SetupGuideEntry> get visibleEntries => entries;

  SetupGuideEntry entry(SetupGuideEntryId id) =>
      entries.firstWhere((entry) => entry.id == id);
}

enum SetupGuideEntryId { bootstrap, navivoxPairHandoff }

class SetupGuideEntry {
  const SetupGuideEntry({
    required this.id,
    required this.label,
    required this.clipboardText,
    required this.successMessage,
    required this.failureMessage,
  });

  final SetupGuideEntryId id;
  final String label;
  final String clipboardText;
  final String successMessage;
  final String failureMessage;
}

const _entries = [
  SetupGuideEntry(
    id: SetupGuideEntryId.bootstrap,
    label: 'Copy one-paste bootstrap',
    clipboardText: _termuxGormesBootstrapCommands,
    successMessage: 'Copied one-paste Termux bootstrap.',
    failureMessage: 'Could not copy one-paste bootstrap.',
  ),
  SetupGuideEntry(
    id: SetupGuideEntryId.navivoxPairHandoff,
    label: 'Copy Navivox pair handoff',
    clipboardText: _termuxNavivoxPairHandoff,
    successMessage: 'Copied Navivox pair handoff.',
    failureMessage: 'Could not copy Navivox pair handoff.',
  ),
];

const _termuxGormesBootstrapCommands = r'''
printf '%s\n' 'This is one pasted Termux command for Navivox setup.' && \
pkg upgrade -y && \
pkg install -y git curl && \
curl -fsSLO https://github.com/TrebuchetDynamics/gormes-agent/releases/latest/download/install.sh && \
printf '%s\n' 'Review install.sh in the pager. Press q to continue install, or Ctrl-C to abort.' && \
less install.sh && \
GORMES_SKIP_SETUP=1 bash install.sh && \
(gormes navivox pair || gormes navivox connect-info)
''';

const _termuxNavivoxPairHandoff = '''
Navivox pair handoff target:
The goal is one terminal interaction maximum: install Termux, paste one command, then continue setup in Navivox.

After Gormes installs, choose Navivox (recommended) when prompted. If the installer prints the recommended next step, run:

gormes navivox pair

That command should start local bridge, generate a pairing token, show a QR, print localhost URL, and wait for Navivox connection.

In Navivox, scan/import the QR or paste the base URL and token here. If this Gormes build does not offer pair yet, run gormes navivox connect-info and paste those values into Navivox only.

Navivox does not install APKs or run Termux commands for you. Do not share pairing tokens in logs, screenshots, issues, or chat transcripts.
''';
