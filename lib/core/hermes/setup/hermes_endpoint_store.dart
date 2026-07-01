/// A saved Hermes endpoint: base URL (non-secret) plus an optional bearer
/// API key (secret).
class HermesEndpointConfig {
  const HermesEndpointConfig({required this.baseUrl, this.apiKey});

  final String baseUrl;
  final String? apiKey;
}

/// Persists the Hermes endpoint the operator connected to, so the app does
/// not require re-entering the base URL/API key on every open. Implementations
/// must never write [HermesEndpointConfig.apiKey] to shared preferences, logs,
/// or other non-secure storage — see docs/product/hermes-agent-interface-plan.md
/// "Replace setup/persistence safely."
abstract interface class HermesEndpointStore {
  Future<HermesEndpointConfig?> load();

  Future<void> save({required String baseUrl, String? apiKey});

  Future<void> clear();
}

/// Default store that persists nothing, so no API key is ever written to
/// insecure storage before a platform-backed store is injected.
class EmptyHermesEndpointStore implements HermesEndpointStore {
  const EmptyHermesEndpointStore();

  @override
  Future<HermesEndpointConfig?> load() async => null;

  @override
  Future<void> save({required String baseUrl, String? apiKey}) async {}

  @override
  Future<void> clear() async {}
}
