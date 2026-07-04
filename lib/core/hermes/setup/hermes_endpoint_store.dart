/// A saved Hermes endpoint: base URL (non-secret) plus an optional bearer
/// API key (secret). [id] and [label] are non-secret profile metadata used by
/// the Hermes connect form to switch between multiple saved endpoints.
class HermesEndpointConfig {
  const HermesEndpointConfig({
    required this.baseUrl,
    this.apiKey,
    this.id,
    this.label,
  });

  final String baseUrl;
  final String? apiKey;
  final String? id;
  final String? label;

  String get displayLabel {
    final trimmed = label?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return baseUrl;
  }
}

/// Persists Hermes endpoints the operator connected to, so the app does not
/// require re-entering the base URL/API key on every open. Implementations must
/// never write [HermesEndpointConfig.apiKey] to shared preferences, logs, or
/// other non-secure storage — see docs/product/hermes-agent-interface-plan.md
/// "Replace setup/persistence safely."
abstract interface class HermesEndpointStore {
  Future<HermesEndpointConfig?> load();

  Future<List<HermesEndpointConfig>> loadProfiles();

  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
  });

  Future<void> deleteProfile(String profileId);

  Future<void> clear();
}

/// Default store that persists nothing, so no API key is ever written to
/// insecure storage before a platform-backed store is injected.
class EmptyHermesEndpointStore implements HermesEndpointStore {
  const EmptyHermesEndpointStore();

  @override
  Future<HermesEndpointConfig?> load() async => null;

  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async => const [];

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
  }) async {}

  @override
  Future<void> deleteProfile(String profileId) async {}

  @override
  Future<void> clear() async {}
}
