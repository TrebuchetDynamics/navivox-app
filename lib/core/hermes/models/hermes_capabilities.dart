import '../../protocol/navivox_json.dart';

class HermesCapabilityDocument {
  const HermesCapabilityDocument({
    required this.object,
    required this.platform,
    required this.model,
    required this.auth,
    required this.features,
    required this.endpoints,
    this.schemaVersion = 1,
    this.profileContext = const HermesProfileContextCapability(),
  });

  factory HermesCapabilityDocument.fromJson(Map<String, Object?> json) {
    final endpointsJson = navivoxMapFieldFromJson(json, 'endpoints');
    final rawSchemaVersion = json['schema_version'];
    return HermesCapabilityDocument(
      object: navivoxStringFromJson(
        json['object'],
        fallback: 'hermes.api_server.capabilities',
      ),
      platform: navivoxStringFromJson(json['platform'], fallback: ''),
      model: navivoxStringFromJson(json['model'], fallback: ''),
      // A missing `schema_version` is a pre-versioning server response and is
      // treated as version 1 rather than an unknown/unsupported version.
      schemaVersion: rawSchemaVersion == null
          ? 1
          : navivoxIntFromJson(rawSchemaVersion),
      profileContext: HermesProfileContextCapability.fromJson(
        navivoxMapFieldFromJson(json, 'profile_context'),
      ),
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
  final int schemaVersion;
  final HermesProfileContextCapability profileContext;
  final HermesAuthCapability auth;
  final Map<String, Object?> features;
  final Map<String, HermesEndpointCapability> endpoints;

  /// Whether this client understands the server's capability schema.
  ///
  /// Capability changes are additive within schema 1; a higher version means
  /// the server may rely on contract shifts this client does not yet
  /// implement, so transport operations are gated off rather than guessed at.
  bool get supportsSchema => schemaVersion == 1;

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

/// Describes how a profile-owned request must carry profile context.
///
/// A server that omits `profile_context` entirely parses to the default
/// (blank) instance below, whose [isSupportedQueryContext] is `false`. That
/// is intentional: Navivox never infers an implicit default profile scope
/// for profile-owned operations.
class HermesProfileContextCapability {
  const HermesProfileContextCapability({
    this.type = '',
    this.name = '',
    this.required = false,
    this.defaultProfileId,
  });

  factory HermesProfileContextCapability.fromJson(Map<String, Object?> json) {
    return HermesProfileContextCapability(
      type: navivoxStringFromJson(json['type'], fallback: ''),
      name: navivoxStringFromJson(json['name'], fallback: ''),
      required: navivoxBoolFromJson(json['required']),
      defaultProfileId: navivoxOptionalStringFromJson(
        json['default_profile_id'],
      ),
    );
  }

  final String type;
  final String name;
  final bool required;
  final String? defaultProfileId;

  /// True only for a declared query-parameter profile context. Endpoints
  /// marked `profile_scoped` are unavailable unless this is true.
  bool get isSupportedQueryContext =>
      type == 'query' &&
      name == 'profile' &&
      required &&
      defaultProfileId == 'default';
}

class HermesAuthCapability {
  const HermesAuthCapability({
    required this.type,
    required this.required,
    this.credentialKind = '',
    this.grantedScopes = const [],
  });

  factory HermesAuthCapability.fromJson(Map<String, Object?> json) {
    return HermesAuthCapability(
      type: navivoxStringFromJson(json['type'], fallback: 'bearer'),
      required: navivoxBoolFromJson(json['required']),
      credentialKind: navivoxStringFromJson(
        json['credential_kind'],
        fallback: '',
      ),
      grantedScopes: List.unmodifiable(
        navivoxStringListFromJson(json['granted_scopes']),
      ),
    );
  }

  final String type;
  final bool required;
  final String credentialKind;
  final List<String> grantedScopes;

  /// Whether the caller's granted scopes satisfy [scope], honoring the
  /// superuser wildcard.
  bool allows(String scope) =>
      grantedScopes.contains('*') || grantedScopes.contains(scope);
}

class HermesEndpointCapability {
  const HermesEndpointCapability({
    required this.method,
    required this.path,
    this.requiredScopes = const [],
    this.profileScoped = false,
  });

  factory HermesEndpointCapability.fromJson(Map<String, Object?> json) {
    return HermesEndpointCapability(
      method: navivoxStringFromJson(json['method'], fallback: '').toUpperCase(),
      path: navivoxStringFromJson(json['path'], fallback: ''),
      requiredScopes: List.unmodifiable(
        navivoxStringListFromJson(json['required_scopes']),
      ),
      profileScoped: navivoxBoolFromJson(json['profile_scoped']),
    );
  }

  final String method;
  final String path;
  final List<String> requiredScopes;
  final bool profileScoped;
}
