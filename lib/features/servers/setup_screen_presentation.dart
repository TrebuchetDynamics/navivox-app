import 'setup_qr_import_presentation.dart';

class SetupScreenPresentation {
  const SetupScreenPresentation();

  String get title => 'Connect to Gormes';

  String get pairingInstructions =>
      'Scan/import the QR from `gormes navivox pair`; use '
      '`gormes navivox connect-info` only as fallback.';

  String get networkHint =>
      'Android emulator: use http://10.0.2.2:<port> for a host gateway. '
      'On a physical Android device, use the host LAN, VPN, or Tailscale '
      'URL from connect-info.';

  String get baseUrlFieldLabel => 'Gateway base URL';

  String get baseUrlFieldSemanticLabel => 'Gateway base URL field';

  String get baseUrlFieldSemanticHint => 'Enter the Gormes gateway base URL.';

  String get tokenFieldLabel => 'Pairing token';

  String get tokenFieldSemanticLabel => 'Pairing token field';

  String get tokenFieldSemanticHint =>
      'Enter the pairing token printed by Gormes.';

  String get importQrButtonLabel => 'Import pairing QR image';

  String tokenVisibilityLabel({required bool showToken}) {
    return showToken ? 'Hide pairing token' : 'Show pairing token';
  }

  String get connectButtonLabel => 'Connect and talk';

  String get connectButtonSemanticHint => 'Connect to Gormes and open chat.';

  SetupScreenNotice qrImportNotice(SetupQrImageImport? result) {
    if (result == null || !result.hasValues) {
      return const SetupScreenNotice.info('No QR image selected.');
    }
    return const SetupScreenNotice.info('Imported QR connection details.');
  }

  SetupScreenNotice qrImportFailureNotice([String? detail]) {
    return SetupScreenNotice.error(
      _safeDetailOrFallback(detail, 'Could not read a Navivox QR image.'),
    );
  }

  SetupScreenNotice validationFailureNotice(String message) {
    return SetupScreenNotice.error(message);
  }

  SetupScreenNotice get connectFailureNotice => const SetupScreenNotice.error(
    'Could not connect to Gormes gateway.',
    recoveryMessage: 'Run `gormes navivox connect-info` on the host and retry.',
  );
}

class SetupScreenNotice {
  const SetupScreenNotice._({
    required this.kind,
    required this.message,
    this.recoveryMessage,
  });

  const SetupScreenNotice.info(String message)
    : this._(kind: SetupScreenNoticeKind.info, message: message);

  const SetupScreenNotice.error(String message, {String? recoveryMessage})
    : this._(
        kind: SetupScreenNoticeKind.error,
        message: message,
        recoveryMessage: recoveryMessage,
      );

  final SetupScreenNoticeKind kind;
  final String message;
  final String? recoveryMessage;

  bool get isError => kind == SetupScreenNoticeKind.error;
}

enum SetupScreenNoticeKind { info, error }

String _safeDetailOrFallback(String? detail, String fallback) {
  final text = detail?.trim();
  if (text == null || text.isEmpty) return fallback;
  if (text.toLowerCase().contains('nvbx_')) return fallback;
  return text;
}
