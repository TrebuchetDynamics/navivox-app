import '../../../protocol/navivox_json.dart';

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
    final normalizedBaseUrl = navivoxOptionalStringFromJson(baseUrl);
    if (normalizedBaseUrl == null) return null;

    return SavedSessionFields(
      baseUrl: normalizedBaseUrl,
      webSocketUrl: navivoxOptionalStringFromJson(webSocketUrl),
      gatewayId: navivoxOptionalStringFromJson(gatewayId),
      lastConnectedAt: navivoxDateTimeFromJson(lastConnectedAt),
    );
  }

  final String baseUrl;
  final String? webSocketUrl;
  final String? gatewayId;
  final DateTime? lastConnectedAt;
}
