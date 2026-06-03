import '../models/connection_import.dart';

/// Operator setup action for a pairing handoff.
///
/// Pairing intents describe what the operator chose without turning pairing
/// tokens into normal presentation copy. Dispatchers may use [token] to connect,
/// but logs, labels, and diagnostics should use [safeSourceLabel].
sealed class PairingIntent {
  const PairingIntent._({required this.action});

  const factory PairingIntent.submitManualHandoff({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  }) = ManualPairingIntent.submitHandoff;

  const factory PairingIntent.retryManualHandoff({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  }) = ManualPairingIntent.retryHandoff;

  const factory PairingIntent.importHandoff(SetupQrImageImport import) =
      ImportedPairingIntent.importHandoff;

  const factory PairingIntent.confirmHandoff(SetupQrImageImport import) =
      ImportedPairingIntent.confirmHandoff;

  const factory PairingIntent.rejectHandoff(SetupQrImageImport import) =
      ImportedPairingIntent.rejectHandoff;

  final PairingIntentAction action;

  PairingHandoffSource get source;
  String? get baseUrl;
  String? get token;
  String? get webSocketUrl;

  bool get isOperatorConfirmation =>
      action == PairingIntentAction.confirmHandoff ||
      action == PairingIntentAction.rejectHandoff;

  String get safeSourceLabel => switch (source) {
    PairingHandoffSource.manual => 'manual entry',
    PairingHandoffSource.qrImage => 'QR image',
    PairingHandoffSource.sharedText => 'shared text',
    PairingHandoffSource.directAppOpen => 'direct app open',
  };
}

enum PairingIntentAction {
  submitManualHandoff,
  importHandoff,
  retryHandoff,
  confirmHandoff,
  rejectHandoff,
}

final class ManualPairingIntent extends PairingIntent {
  const ManualPairingIntent.submitHandoff({
    required this.baseUrl,
    this.token,
    this.webSocketUrl,
  }) : super._(action: PairingIntentAction.submitManualHandoff);

  const ManualPairingIntent.retryHandoff({
    required this.baseUrl,
    this.token,
    this.webSocketUrl,
  }) : super._(action: PairingIntentAction.retryHandoff);

  @override
  PairingHandoffSource get source => PairingHandoffSource.manual;
  @override
  final String baseUrl;
  @override
  final String? token;
  @override
  final String? webSocketUrl;
}

final class ImportedPairingIntent extends PairingIntent {
  const ImportedPairingIntent.importHandoff(this.import)
    : super._(action: PairingIntentAction.importHandoff);

  const ImportedPairingIntent.confirmHandoff(this.import)
    : super._(action: PairingIntentAction.confirmHandoff);

  const ImportedPairingIntent.rejectHandoff(this.import)
    : super._(action: PairingIntentAction.rejectHandoff);

  final SetupQrImageImport import;

  @override
  PairingHandoffSource get source => import.source;
  @override
  String? get baseUrl => import.baseUrl;
  @override
  String? get token => import.token;
  @override
  String? get webSocketUrl => import.webSocketUrl;
}
