import '../../../../../protocol/navivox_json.dart';

import '../connection/session_connection_metadata.dart';

/// Normalized non-secret session metadata loaded from persistence.
///
/// A blank or missing [baseUrl] invalidates the whole saved session. Optional
/// metadata keeps the same trimming/blank-clearing semantics used when saving.
class SavedSessionFields {
  const SavedSessionFields({
    required this.baseUrl,
    this.webSocketUrl,
    this.gatewayId,
    this.lastConnectedAt,
  });

  static SavedSessionFields? fromStoredValues({
    required Object? baseUrl,
    Object? webSocketUrl,
    Object? gatewayId,
    Object? lastConnectedAt,
  }) {
    final metadata = SessionConnectionMetadata.maybeFromStoredValues(
      baseUrl: baseUrl,
      webSocketUrl: webSocketUrl,
      gatewayId: gatewayId,
    );
    if (metadata == null) return null;

    return SavedSessionFields(
      baseUrl: metadata.baseUrl,
      webSocketUrl: metadata.webSocketUrl,
      gatewayId: metadata.gatewayId,
      lastConnectedAt: navivoxDateTimeFromJson(lastConnectedAt),
    );
  }

  final String baseUrl;
  final String? webSocketUrl;
  final String? gatewayId;
  final DateTime? lastConnectedAt;
}
