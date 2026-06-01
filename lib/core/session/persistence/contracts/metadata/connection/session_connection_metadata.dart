import '../../../../../protocol/navivox_json.dart';

/// Normalized non-secret gateway connection metadata shared by saved-session
/// persistence contracts.
class SessionConnectionMetadata {
  const SessionConnectionMetadata({
    required this.baseUrl,
    this.webSocketUrl,
    this.gatewayId,
  });

  factory SessionConnectionMetadata.fromStoredValues({
    required Object? baseUrl,
    Object? webSocketUrl,
    Object? gatewayId,
  }) {
    final normalizedBaseUrl = navivoxOptionalStringFromJson(baseUrl);
    if (normalizedBaseUrl == null) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'must not be blank');
    }

    return _fromNormalizedValues(
      baseUrl: normalizedBaseUrl,
      webSocketUrl: webSocketUrl,
      gatewayId: gatewayId,
    );
  }

  static SessionConnectionMetadata? maybeFromStoredValues({
    required Object? baseUrl,
    Object? webSocketUrl,
    Object? gatewayId,
  }) {
    final normalizedBaseUrl = navivoxOptionalStringFromJson(baseUrl);
    if (normalizedBaseUrl == null) return null;

    return _fromNormalizedValues(
      baseUrl: normalizedBaseUrl,
      webSocketUrl: webSocketUrl,
      gatewayId: gatewayId,
    );
  }

  static SessionConnectionMetadata _fromNormalizedValues({
    required String baseUrl,
    Object? webSocketUrl,
    Object? gatewayId,
  }) {
    return SessionConnectionMetadata(
      baseUrl: baseUrl,
      webSocketUrl: navivoxOptionalStringFromJson(webSocketUrl),
      gatewayId: navivoxOptionalStringFromJson(gatewayId),
    );
  }

  final String baseUrl;
  final String? webSocketUrl;
  final String? gatewayId;
}
