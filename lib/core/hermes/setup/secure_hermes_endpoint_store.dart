import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hermes_endpoint_store.dart';

/// [HermesEndpointStore] backed by shared preferences (base URL) and the
/// platform secure enclave (API key). Navivox never stores the Hermes API
/// key in shared preferences.
class SecureHermesEndpointStore implements HermesEndpointStore {
  SecureHermesEndpointStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _baseUrlPreferenceKey = 'navivox.hermes.base_url';
  static const _apiKeySecureStorageKey = 'navivox.hermes.api_key';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<HermesEndpointConfig?> load() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
    final baseUrl = prefs.getString(_baseUrlPreferenceKey);
    if (baseUrl == null || baseUrl.isEmpty) return null;
    final apiKey = await _secureStorage.read(key: _apiKeySecureStorageKey);
    return HermesEndpointConfig(baseUrl: baseUrl, apiKey: apiKey);
  }

  @override
  Future<void> save({required String baseUrl, String? apiKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPreferenceKey, baseUrl);
    if (apiKey == null || apiKey.isEmpty) {
      await _secureStorage.delete(key: _apiKeySecureStorageKey);
    } else {
      await _secureStorage.write(key: _apiKeySecureStorageKey, value: apiKey);
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlPreferenceKey);
    await _secureStorage.delete(key: _apiKeySecureStorageKey);
  }
}
