import 'package:navivox/core/hermes/setup/hermes_endpoint_store.dart';

class FakeHermesEndpointStore implements HermesEndpointStore {
  FakeHermesEndpointStore({HermesEndpointConfig? initial}) : _config = initial;

  HermesEndpointConfig? _config;
  final List<HermesEndpointConfig> saveCalls = [];
  int clearCalls = 0;

  @override
  Future<HermesEndpointConfig?> load() async => _config;

  @override
  Future<void> save({required String baseUrl, String? apiKey}) async {
    _config = HermesEndpointConfig(baseUrl: baseUrl, apiKey: apiKey);
    saveCalls.add(_config!);
  }

  @override
  Future<void> clear() async {
    _config = null;
    clearCalls += 1;
  }
}
