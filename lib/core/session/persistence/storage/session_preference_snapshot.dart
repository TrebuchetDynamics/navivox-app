import '../contracts/saved_session.dart';
import '../contracts/saved_session_fields.dart';

/// Pure projection from raw preference values to saved session metadata.
///
/// Keeping this separate from SharedPreferences I/O makes the reconnect
/// persistence read contract replayable: missing base URL invalidates the
/// snapshot, optional URL-shaped metadata is sanitized or dropped by
/// [SavedSessionFields], and malformed timestamps become absent instead of
/// preventing reconnect UI from loading the remaining non-secret metadata.
SavedSession? savedSessionFromPreferenceSnapshot({
  required Object? baseUrl,
  Object? webSocketUrl,
  Object? gatewayId,
  Object? lastConnectedAt,
}) {
  final fields = savedSessionFieldsFromPreferenceSnapshot(
    baseUrl: baseUrl,
    webSocketUrl: webSocketUrl,
    gatewayId: gatewayId,
    lastConnectedAt: lastConnectedAt,
  );
  if (fields == null) return null;

  return SavedSession(
    baseUrl: fields.baseUrl,
    webSocketUrl: fields.webSocketUrl,
    gatewayId: fields.gatewayId,
    lastConnectedAt: fields.lastConnectedAt,
  );
}

/// True only when the stored values can replay into a loadable saved session.
bool hasSavedSessionInPreferenceSnapshot({
  required Object? baseUrl,
  Object? webSocketUrl,
  Object? gatewayId,
  Object? lastConnectedAt,
}) {
  return savedSessionFieldsFromPreferenceSnapshot(
        baseUrl: baseUrl,
        webSocketUrl: webSocketUrl,
        gatewayId: gatewayId,
        lastConnectedAt: lastConnectedAt,
      ) !=
      null;
}

SavedSessionFields? savedSessionFieldsFromPreferenceSnapshot({
  required Object? baseUrl,
  Object? webSocketUrl,
  Object? gatewayId,
  Object? lastConnectedAt,
}) {
  return SavedSessionFields.fromStoredValues(
    baseUrl: baseUrl,
    webSocketUrl: webSocketUrl,
    gatewayId: gatewayId,
    lastConnectedAt: lastConnectedAt,
  );
}
