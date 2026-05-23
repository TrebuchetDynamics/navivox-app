class SetupGuidePresentation {
  const SetupGuidePresentation();

  String get introCopy =>
      'Run Gormes on this Android device with Termux: install Termux from '
      'F-Droid or official GitHub Releases, then paste one command from '
      'Navivox. The command updates packages, installs git/curl, downloads '
      'and pauses for `install.sh` review, then installs Gormes. After '
      'Gormes installs, choose Navivox (recommended) and run `gormes navivox '
      'pair` to continue setup in Navivox. Navivox cannot silently install '
      'Gormes; if pair is not available in this Gormes build, use the '
      'connect-info fallback and paste `gormes navivox connect-info` values '
      'here.';

  List<SetupGuideEntry> get entries => _entries;

  SetupGuideEntry entry(SetupGuideEntryId id) =>
      entries.firstWhere((entry) => entry.id == id);
}

enum SetupGuideEntryId {
  bootstrap,
  downloadLinks,
  postInstallChecks,
  navivoxPairHandoff,
  gatewayLifecycle,
  bootHelper,
  connectionHint,
  storageCommand,
}

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
    id: SetupGuideEntryId.downloadLinks,
    label: 'Copy Termux download links',
    clipboardText: _termuxDownloadLinks,
    successMessage: 'Copied Termux download links.',
    failureMessage: 'Could not copy Termux download links.',
  ),
  SetupGuideEntry(
    id: SetupGuideEntryId.postInstallChecks,
    label: 'Copy post-install checks',
    clipboardText: _termuxPostInstallChecks,
    successMessage: 'Copied post-install Termux checks.',
    failureMessage: 'Could not copy post-install checks.',
  ),
  SetupGuideEntry(
    id: SetupGuideEntryId.navivoxPairHandoff,
    label: 'Copy Navivox pair handoff',
    clipboardText: _termuxNavivoxPairHandoff,
    successMessage: 'Copied Navivox pair handoff.',
    failureMessage: 'Could not copy Navivox pair handoff.',
  ),
  SetupGuideEntry(
    id: SetupGuideEntryId.gatewayLifecycle,
    label: 'Copy Termux gateway lifecycle',
    clipboardText: _termuxGatewayLifecycle,
    successMessage: 'Copied Termux gateway lifecycle.',
    failureMessage: 'Could not copy gateway lifecycle.',
  ),
  SetupGuideEntry(
    id: SetupGuideEntryId.bootHelper,
    label: 'Copy Termux:Boot helper',
    clipboardText: _termuxBootHelper,
    successMessage: 'Copied Termux:Boot helper.',
    failureMessage: 'Could not copy Termux:Boot helper.',
  ),
  SetupGuideEntry(
    id: SetupGuideEntryId.connectionHint,
    label: 'Copy same-device connection hint',
    clipboardText: _termuxSameDeviceConnectionHint,
    successMessage: 'Copied same-device connection hint.',
    failureMessage: 'Could not copy connection hint.',
  ),
  SetupGuideEntry(
    id: SetupGuideEntryId.storageCommand,
    label: 'Copy optional storage command',
    clipboardText: _termuxOptionalStorageCommand,
    successMessage: 'Copied optional Termux storage command.',
    failureMessage: 'Could not copy storage command.',
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

const _termuxDownloadLinks = '''
Termux install sources:
- Official site: https://termux.dev/en/
- Preferred Android package: https://f-droid.org/packages/com.termux/
- Official GitHub Releases: https://github.com/termux/termux-app/releases

Use one signing source for Termux and plugins. Do not mix F-Droid, GitHub, or other APK sources on the same install.
''';

const _termuxPostInstallChecks = '''
After bash install.sh finishes in Termux, run these checks:

gormes version
gormes doctor --offline
gormes navivox connect-info

If connect-info prints a pairing token, paste it only into Navivox. Do not share tokens in logs, screenshots, issues, or chat transcripts.
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

const _termuxGatewayLifecycle = '''
Termux gateway foreground/tmux lifecycle:
Run the Gormes gateway in a Termux foreground tmux session, then use status and connect-info from another Termux session.

tmux new-session -s gormes-gateway "gormes gateway"
gormes gateway status
gormes navivox connect-info
gormes gateway stop

termux-wake-lock and Android battery settings are best-effort only. Android may still stop background processes.
Paste pairing tokens only into Navivox; do not share tokens in logs or screenshots.
''';

const _termuxBootHelper = '''
Optional Termux:Boot gateway auto-start helper:
Only use this after Gormes works manually in Termux and after installing the Termux:Boot plugin from the same APK source as Termux.

Commands:
gormes gateway boot-install
gormes gateway status
gormes navivox connect-info

Rollback:
gormes gateway boot-uninstall

The boot-install command writes ~/.termux/boot/gormes-gateway.sh. Reboot Android to let Termux:Boot start the tmux gateway, then verify with gormes gateway status.
Android may still stop background processes. Navivox does not install APKs or run these commands for you.
''';

const _termuxSameDeviceConnectionHint = '''
Navivox connection hints:
- Same Android device (Gormes in Termux): use the loopback URL printed by `gormes navivox connect-info`, usually http://127.0.0.1:<port>.
- Android emulator to host Gormes: use http://10.0.2.2:<port>.
- Physical Android device to separate host Gormes: use the LAN, VPN, or Tailscale URL from `gormes navivox connect-info`.

Paste pairing tokens only into Navivox. Do not share tokens in logs, screenshots, issues, or chat transcripts.
''';

const _termuxOptionalStorageCommand = '''
Optional Termux shared-storage access:
Only run this if you need to move logs, screenshots, or exported files between Android storage and Termux.

Command:
termux-setup-storage

Android will show an Android storage permission prompt. This is not required for the normal Gormes install path.
''';
