import '../models/connection_import.dart';
import '../shared/connection_import_parser.dart';

/// Parses the platform-channel shape used by Android connect intents.
///
/// Native code may deliver either a plain payload string or a map containing
/// the payload plus handoff provenance metadata.
SetupQrImageImport? parseNavivoxConnectIntentPayload(Object? payload) {
  if (payload is String) {
    final text = payload.trim();
    if (text.isEmpty) return null;
    return parseNavivoxConnectionImportPayload(text);
  }
  if (payload is! Map) return null;
  final text = payload['payload']?.toString().trim();
  if (text == null || text.isEmpty) return null;
  final parsed = parseNavivoxConnectionImportPayload(text);
  if (parsed == null) return null;
  return parsed.withSource(pairingHandoffSourceFromPlatformPayload(payload['source']));
}

PairingHandoffSource pairingHandoffSourceFromPlatformPayload(Object? value) {
  return switch (value?.toString().trim()) {
    'direct_app_open' => PairingHandoffSource.directAppOpen,
    'shared_text' => PairingHandoffSource.sharedText,
    _ => PairingHandoffSource.manual,
  };
}
