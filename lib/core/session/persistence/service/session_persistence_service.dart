import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/session_text.dart';
import '../contracts/saved_session.dart';
import '../contracts/saved_session_fields.dart';
import '../storage/session_preference_keys.dart';
import '../storage/session_preference_write_plan.dart';

/// Persists non-secret gateway metadata for later reconnect flows.
///
/// Pairing handoff tokens are bootstrap-only and must not be stored here.
/// Silent reconnect remains disabled until a secure durable credential adapter
/// exists for the saved Gateway identity.
class SessionPersistenceService {
  SessionPersistenceService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  SharedPreferences? _prefs;

  Future<void> ensureInitialized() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // SharedPreferences not available (e.g. test without mock).
    }
  }

  /// Save non-secret gateway metadata after a successful gateway connection.
  Future<void> saveConnection({
    required String baseUrl,
    String? webSocketUrl,
    String? gatewayId,
  }) async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return;
    final writes = sessionPreferenceWritesForConnection(
      baseUrl: baseUrl,
      webSocketUrl: webSocketUrl,
      gatewayId: gatewayId,
      connectedAt: _clock(),
    );
    await _applyPreferenceWrites(prefs, writes);
  }

  /// Load saved connection state. Returns null if no session is saved.
  Future<SavedSession?> loadSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return null;
    final fields = SavedSessionFields.fromStoredValues(
      baseUrl: prefs.getString(SessionPreferenceKeys.baseUrl),
      webSocketUrl: prefs.getString(SessionPreferenceKeys.webSocketUrl),
      gatewayId: prefs.getString(SessionPreferenceKeys.gatewayId),
      lastConnectedAt: prefs.getString(SessionPreferenceKeys.lastConnectedAt),
    );
    if (fields == null) return null;

    return SavedSession(
      baseUrl: fields.baseUrl,
      webSocketUrl: fields.webSocketUrl,
      gatewayId: fields.gatewayId,
      lastConnectedAt: fields.lastConnectedAt,
    );
  }

  /// Remove saved session. Call when user explicitly disconnects,
  /// or when reconnect fails with an expired/revoked credential.
  Future<void> clearSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return;
    await _applyPreferenceWrites(prefs, sessionPreferenceWritesForClear);
  }

  /// Check if a saved session exists without loading all fields.
  Future<bool> hasSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return false;
    final baseUrl = prefs.getString(SessionPreferenceKeys.baseUrl);
    return isNonBlankSessionText(baseUrl);
  }
}

Future<void> _applyPreferenceWrites(
  SharedPreferences prefs,
  Iterable<SessionPreferenceWrite> writes,
) async {
  for (final write in writes) {
    final value = write.value;
    if (value == null) {
      await prefs.remove(write.key);
    } else {
      await prefs.setString(write.key, value);
    }
  }
}
