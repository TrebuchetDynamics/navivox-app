import '../../protocol/navivox_json.dart';

class HermesCapabilityDocument {
  const HermesCapabilityDocument({
    required this.object,
    required this.platform,
    required this.model,
    required this.auth,
    required this.features,
    required this.endpoints,
  });

  factory HermesCapabilityDocument.fromJson(Map<String, Object?> json) {
    final endpointsJson = navivoxMapFieldFromJson(json, 'endpoints');
    return HermesCapabilityDocument(
      object: navivoxStringFromJson(
        json['object'],
        fallback: 'hermes.api_server.capabilities',
      ),
      platform: navivoxStringFromJson(json['platform'], fallback: ''),
      model: navivoxStringFromJson(json['model'], fallback: ''),
      auth: HermesAuthCapability.fromJson(
        navivoxMapFieldFromJson(json, 'auth'),
      ),
      features: navivoxMapFieldFromJson(json, 'features'),
      endpoints: {
        for (final entry in endpointsJson.entries)
          entry.key: HermesEndpointCapability.fromJson(
            navivoxMapFromJson(entry.value),
          ),
      },
    );
  }

  final String object;
  final String platform;
  final String model;
  final HermesAuthCapability auth;
  final Map<String, Object?> features;
  final Map<String, HermesEndpointCapability> endpoints;

  bool supportsFeature(String feature) {
    return navivoxBoolFromJson(features[feature]);
  }

  bool advertisesEndpoint(String name, String method, String path) {
    final endpoint = endpoints[name];
    return endpoint != null &&
        endpoint.method == method.toUpperCase() &&
        endpoint.path == path;
  }
}

class HermesAuthCapability {
  const HermesAuthCapability({required this.type, required this.required});

  factory HermesAuthCapability.fromJson(Map<String, Object?> json) {
    return HermesAuthCapability(
      type: navivoxStringFromJson(json['type'], fallback: 'bearer'),
      required: navivoxBoolFromJson(json['required']),
    );
  }

  final String type;
  final bool required;
}

class HermesEndpointCapability {
  const HermesEndpointCapability({required this.method, required this.path});

  factory HermesEndpointCapability.fromJson(Map<String, Object?> json) {
    return HermesEndpointCapability(
      method: navivoxStringFromJson(json['method'], fallback: '').toUpperCase(),
      path: navivoxStringFromJson(json['path'], fallback: ''),
    );
  }

  final String method;
  final String path;
}
