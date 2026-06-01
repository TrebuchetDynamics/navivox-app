import '../contracts/saved_connection_fields.dart';
import 'session_preference_keys.dart';

/// A single deterministic mutation against saved session preferences.
class SessionPreferenceWrite {
  const SessionPreferenceWrite.set(this.key, String this.value);

  const SessionPreferenceWrite.remove(this.key) : value = null;

  final String key;
  final String? value;

  bool get isRemove => value == null;
}

/// Preference writes for persisting a successful non-secret gateway connection.
///
/// This is intentionally pure so persistence safety rules are visible and
/// testable without a SharedPreferences instance: pairing tokens are always
/// removed, optional blank metadata becomes removals, and timestamps are stored
/// in UTC ISO-8601 form.
List<SessionPreferenceWrite> sessionPreferenceWritesForConnection({
  required String baseUrl,
  required String? webSocketUrl,
  required String? gatewayId,
  required DateTime connectedAt,
}) {
  final fields = SavedConnectionFields.fromInput(
    baseUrl: baseUrl,
    webSocketUrl: webSocketUrl,
    gatewayId: gatewayId,
  );
  final timestamp = connectedAt.toUtc().toIso8601String();

  return [
    const SessionPreferenceWrite.remove(SessionPreferenceKeys.legacyToken),
    SessionPreferenceWrite.set(SessionPreferenceKeys.baseUrl, fields.baseUrl),
    _writeOptional(SessionPreferenceKeys.webSocketUrl, fields.webSocketUrl),
    _writeOptional(SessionPreferenceKeys.gatewayId, fields.gatewayId),
    SessionPreferenceWrite.set(
      SessionPreferenceKeys.lastConnectedAt,
      timestamp,
    ),
  ];
}

/// Preference writes for removing all saved session state.
const sessionPreferenceWritesForClear = [
  SessionPreferenceWrite.remove(SessionPreferenceKeys.baseUrl),
  SessionPreferenceWrite.remove(SessionPreferenceKeys.legacyToken),
  SessionPreferenceWrite.remove(SessionPreferenceKeys.webSocketUrl),
  SessionPreferenceWrite.remove(SessionPreferenceKeys.lastConnectedAt),
  SessionPreferenceWrite.remove(SessionPreferenceKeys.gatewayId),
];

SessionPreferenceWrite _writeOptional(String key, String? value) {
  return value == null
      ? SessionPreferenceWrite.remove(key)
      : SessionPreferenceWrite.set(key, value);
}
