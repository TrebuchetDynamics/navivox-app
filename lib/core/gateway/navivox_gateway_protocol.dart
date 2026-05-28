import '../protocol/navivox_memory.dart';

const navivoxWebSocketProtocol = 'navivox.v1';
const navivoxWebSocketTokenProtocolPrefix = 'gormes.navivox.token.';

class NavivoxGatewayStatus {
  const NavivoxGatewayStatus({
    required this.enabled,
    required this.protocolVersion,
    required this.websocketProtocols,
    required this.capabilities,
    required this.sessionCount,
    required this.webSocketConnectionCount,
    this.capabilitiesUrl,
    this.gatewayId,
  });

  factory NavivoxGatewayStatus.fromJson(Map<String, Object?> json) {
    return NavivoxGatewayStatus(
      enabled: json['enabled'] == true,
      protocolVersion: _stringFromJson(
        json['protocol_version'],
        fallback: navivoxWebSocketProtocol,
      ),
      websocketProtocols: _stringListFromJson(json['websocket_protocols']),
      capabilities: _stringListFromJson(json['capabilities']),
      sessionCount: _intFromJson(json['sessions']),
      webSocketConnectionCount: _intFromJson(json['ws_connections']),
      capabilitiesUrl: _optionalStringFromJson(json['capabilities_url']),
      gatewayId: _optionalStringFromJson(json['gateway_id']),
    );
  }

  final bool enabled;
  final String protocolVersion;
  final List<String> websocketProtocols;
  final List<String> capabilities;
  final int sessionCount;
  final int webSocketConnectionCount;
  final String? capabilitiesUrl;
  final String? gatewayId;

  bool get hasGatewayIdentity =>
      gatewayId != null && gatewayId!.trim().isNotEmpty;

  bool supports(String capability) => capabilities.contains(capability);
}

class NavivoxCapabilityDocument {
  const NavivoxCapabilityDocument({
    required this.object,
    required this.protocolVersion,
    required this.capabilities,
    required this.auth,
    required this.healthAliases,
    required this.endpoints,
    required this.profileManagement,
    required this.attachments,
    required this.voice,
    required this.streams,
    required this.durableReconnect,
  });

  factory NavivoxCapabilityDocument.fromJson(Map<String, Object?> json) {
    return NavivoxCapabilityDocument(
      object: _stringFromJson(json['object'], fallback: ''),
      protocolVersion: _stringFromJson(json['protocol_version'], fallback: ''),
      capabilities: _stringListFromJson(json['capabilities']),
      auth: NavivoxCapabilityAuth.fromJson(_mapFromJson(json['auth'])),
      healthAliases: _stringListFromJson(
        _mapFromJson(json['health'])['aliases'],
      ),
      endpoints: _listFromJson(json['endpoints'])
          .whereType<Map>()
          .map(
            (endpoint) => NavivoxCapabilityEndpoint.fromJson(
              Map<String, Object?>.from(endpoint),
            ),
          )
          .toList(growable: false),
      profileManagement: NavivoxProfileManagementCapability.fromJson(
        _mapFromJson(json['profile_management']),
      ),
      attachments: NavivoxAttachmentCapability.fromJson(
        _mapFromJson(json['attachments']),
      ),
      voice: NavivoxVoiceProtocolCapability.fromJson(
        _mapFromJson(json['voice']),
      ),
      streams: NavivoxStreamCapability.fromJson(_mapFromJson(json['streams'])),
      durableReconnect: NavivoxDurableReconnectCapability.fromJson(
        _mapFromJson(json['durable_reconnect']),
      ),
    );
  }

  final String object;
  final String protocolVersion;
  final List<String> capabilities;
  final NavivoxCapabilityAuth auth;
  final List<String> healthAliases;
  final List<NavivoxCapabilityEndpoint> endpoints;
  final NavivoxProfileManagementCapability profileManagement;
  final NavivoxAttachmentCapability attachments;
  final NavivoxVoiceProtocolCapability voice;
  final NavivoxStreamCapability streams;
  final NavivoxDurableReconnectCapability durableReconnect;

  bool supports(String capability) => capabilities.contains(capability);

  bool advertisesEndpoint(String method, String path) {
    return endpoints.any(
      (endpoint) => endpoint.method == method && endpoint.path == path,
    );
  }
}

class NavivoxDurableReconnectCapability {
  const NavivoxDurableReconnectCapability({
    required this.supported,
    required this.issueEndpoint,
    required this.authMethods,
    required this.platforms,
    required this.effectiveSecurity,
    required this.blockedReason,
  });

  factory NavivoxDurableReconnectCapability.fromJson(
    Map<String, Object?> json,
  ) {
    return NavivoxDurableReconnectCapability(
      supported: json['supported'] == true,
      issueEndpoint: _stringFromJson(json['issue_endpoint'], fallback: ''),
      authMethods: _stringListFromJson(json['auth_methods']),
      platforms: _stringListFromJson(json['platforms']),
      effectiveSecurity: _stringFromJson(
        json['effective_security'],
        fallback: '',
      ),
      blockedReason: _stringFromJson(json['blocked_reason'], fallback: ''),
    );
  }

  final bool supported;
  final String issueEndpoint;
  final List<String> authMethods;
  final List<String> platforms;
  final String effectiveSecurity;
  final String blockedReason;

  ReconnectReadinessKind get readinessKind {
    if (!supported) return ReconnectReadinessKind.unsupported;
    if (blockedReason.trim().isNotEmpty) return ReconnectReadinessKind.blocked;
    return ReconnectReadinessKind.available;
  }
}

enum ReconnectReadinessKind { unknown, unsupported, blocked, available, saved }

class NavivoxCapabilityAuth {
  const NavivoxCapabilityAuth({
    required this.mode,
    required this.headers,
    required this.webSocketProtocols,
  });

  factory NavivoxCapabilityAuth.fromJson(Map<String, Object?> json) {
    return NavivoxCapabilityAuth(
      mode: _stringFromJson(json['mode'], fallback: ''),
      headers: _stringListFromJson(json['headers']),
      webSocketProtocols: _stringListFromJson(json['websocket_protocols']),
    );
  }

  final String mode;
  final List<String> headers;
  final List<String> webSocketProtocols;
}

class NavivoxCapabilityEndpoint {
  const NavivoxCapabilityEndpoint({
    required this.method,
    required this.path,
    required this.auth,
    required this.stability,
    required this.description,
  });

  factory NavivoxCapabilityEndpoint.fromJson(Map<String, Object?> json) {
    return NavivoxCapabilityEndpoint(
      method: _stringFromJson(json['method'], fallback: ''),
      path: _stringFromJson(json['path'], fallback: ''),
      auth: _stringFromJson(json['auth'], fallback: ''),
      stability: _stringFromJson(json['stability'], fallback: ''),
      description: _stringFromJson(json['description'], fallback: ''),
    );
  }

  final String method;
  final String path;
  final String auth;
  final String stability;
  final String description;
}

class NavivoxStreamCapability {
  const NavivoxStreamCapability({
    required this.canonicalEndpoint,
    required this.transport,
    required this.eventKinds,
    required this.openAiRunsBridge,
  });

  factory NavivoxStreamCapability.fromJson(Map<String, Object?> json) {
    return NavivoxStreamCapability(
      canonicalEndpoint: _stringFromJson(
        json['canonical_endpoint'],
        fallback: '',
      ),
      transport: _stringFromJson(json['transport'], fallback: ''),
      eventKinds: _stringListFromJson(json['event_kinds']),
      openAiRunsBridge: json['openai_runs_bridge'] == true,
    );
  }

  final String canonicalEndpoint;
  final String transport;
  final List<String> eventKinds;
  final bool openAiRunsBridge;
}

class NavivoxProfileManagementCapability {
  const NavivoxProfileManagementCapability({
    required this.contactsEndpoint,
    required this.routingEndpoint,
    required this.createFromSeedEndpoint,
    required this.dashboardApiExposed,
    required this.supportedActions,
    required this.unsupportedActions,
    required this.profileContractParts,
  });

  factory NavivoxProfileManagementCapability.fromJson(
    Map<String, Object?> json,
  ) {
    return NavivoxProfileManagementCapability(
      contactsEndpoint: _stringFromJson(
        json['contacts_endpoint'],
        fallback: '',
      ),
      routingEndpoint: _stringFromJson(json['routing_endpoint'], fallback: ''),
      createFromSeedEndpoint: _stringFromJson(
        json['create_from_seed_endpoint'],
        fallback: '',
      ),
      dashboardApiExposed: json['dashboard_api_exposed'] == true,
      supportedActions: _stringListFromJson(json['supported_actions']),
      unsupportedActions: _stringListFromJson(json['unsupported_actions']),
      profileContractParts: _stringListFromJson(json['profile_contract_parts']),
    );
  }

  final String contactsEndpoint;
  final String routingEndpoint;
  final String createFromSeedEndpoint;
  final bool dashboardApiExposed;
  final List<String> supportedActions;
  final List<String> unsupportedActions;
  final List<String> profileContractParts;

  bool supportsAction(String action) => supportedActions.contains(action);
}

class NavivoxAttachmentCapability {
  const NavivoxAttachmentCapability({
    required this.maxRequestBytes,
    required this.opaqueUploadIds,
    required this.rawLocalPathsAccepted,
    required this.workspaceFileAttach,
    required this.mimeAllowlist,
    required this.retention,
  });

  factory NavivoxAttachmentCapability.fromJson(Map<String, Object?> json) {
    return NavivoxAttachmentCapability(
      maxRequestBytes: _intFromJson(json['max_request_bytes']),
      opaqueUploadIds: json['opaque_upload_ids'] == true,
      rawLocalPathsAccepted: json['raw_local_paths_accepted'] == true,
      workspaceFileAttach: json['workspace_file_attach'] == true,
      mimeAllowlist: _stringListFromJson(json['mime_allowlist']),
      retention: _stringFromJson(json['retention'], fallback: ''),
    );
  }

  final int maxRequestBytes;
  final bool opaqueUploadIds;
  final bool rawLocalPathsAccepted;
  final bool workspaceFileAttach;
  final List<String> mimeAllowlist;
  final String retention;

  bool get uploadsAvailable =>
      opaqueUploadIds && !rawLocalPathsAccepted && mimeAllowlist.isNotEmpty;
}

class NavivoxVoiceProtocolCapability {
  const NavivoxVoiceProtocolCapability({
    required this.deviceTranscribedTextTurns,
    required this.rawAudioUpload,
    required this.voiceProfilesEndpoint,
    required this.runRecordsEndpoint,
    required this.sttProviders,
    required this.ttsProviders,
  });

  factory NavivoxVoiceProtocolCapability.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProtocolCapability(
      deviceTranscribedTextTurns: json['device_transcribed_text_turns'] == true,
      rawAudioUpload: json['raw_audio_upload'] == true,
      voiceProfilesEndpoint: _stringFromJson(
        json['voice_profiles_endpoint'],
        fallback: '',
      ),
      runRecordsEndpoint: _stringFromJson(
        json['run_records_endpoint'],
        fallback: '',
      ),
      sttProviders: _stringListFromJson(json['stt_providers']),
      ttsProviders: _stringListFromJson(json['tts_providers']),
    );
  }

  final bool deviceTranscribedTextTurns;
  final bool rawAudioUpload;
  final String voiceProfilesEndpoint;
  final String runRecordsEndpoint;
  final List<String> sttProviders;
  final List<String> ttsProviders;
}

class NavivoxProfileVoiceProfile {
  const NavivoxProfileVoiceProfile({
    this.sttProvider = '',
    this.ttsProvider = '',
    this.voiceId = '',
    this.languagePolicy = '',
    this.fallbackVoice = '',
  });

  factory NavivoxProfileVoiceProfile.fromJson(Map<String, Object?> json) {
    return NavivoxProfileVoiceProfile(
      sttProvider: _stringFromJson(json['stt_provider'], fallback: ''),
      ttsProvider: _stringFromJson(json['tts_provider'], fallback: ''),
      voiceId: _stringFromJson(json['voice_id'], fallback: ''),
      languagePolicy: _stringFromJson(json['language_policy'], fallback: ''),
      fallbackVoice: _stringFromJson(json['fallback_voice'], fallback: ''),
    );
  }

  final String sttProvider;
  final String ttsProvider;
  final String voiceId;
  final String languagePolicy;
  final String fallbackVoice;

  Map<String, Object?> toJson() {
    return {
      if (sttProvider.trim().isNotEmpty) 'stt_provider': sttProvider.trim(),
      if (ttsProvider.trim().isNotEmpty) 'tts_provider': ttsProvider.trim(),
      if (voiceId.trim().isNotEmpty) 'voice_id': voiceId.trim(),
      if (languagePolicy.trim().isNotEmpty)
        'language_policy': languagePolicy.trim(),
      if (fallbackVoice.trim().isNotEmpty)
        'fallback_voice': fallbackVoice.trim(),
    };
  }
}

class NavivoxVoiceProviderMatrix {
  const NavivoxVoiceProviderMatrix({
    this.sttProviders = const [],
    this.ttsProviders = const [],
  });

  factory NavivoxVoiceProviderMatrix.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProviderMatrix(
      sttProviders: _stringListFromJson(json['stt']),
      ttsProviders: _stringListFromJson(json['tts']),
    );
  }

  final List<String> sttProviders;
  final List<String> ttsProviders;
}

class NavivoxVoiceCredentialStatus {
  const NavivoxVoiceCredentialStatus({
    required this.configured,
    required this.required,
    required this.status,
    this.source = '',
  });

  factory NavivoxVoiceCredentialStatus.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceCredentialStatus(
      configured: json['configured'] == true,
      required: json['required'] == true,
      status: _stringFromJson(json['status'], fallback: ''),
      source: _stringFromJson(json['source'], fallback: ''),
    );
  }

  final bool configured;
  final bool required;
  final String status;
  final String source;
}

class NavivoxVoiceProfileFieldError {
  const NavivoxVoiceProfileFieldError({
    required this.field,
    required this.code,
    required this.message,
  });

  factory NavivoxVoiceProfileFieldError.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProfileFieldError(
      field: _stringFromJson(json['field'], fallback: ''),
      code: _stringFromJson(json['code'], fallback: ''),
      message: _stringFromJson(json['message'], fallback: ''),
    );
  }

  final String field;
  final String code;
  final String message;
}

class NavivoxVoiceProfileValidation {
  const NavivoxVoiceProfileValidation({
    required this.profileId,
    required this.voiceProfile,
    required this.valid,
    this.errors = const [],
    this.credentialStatusRefs = const {},
  });

  factory NavivoxVoiceProfileValidation.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProfileValidation(
      profileId: _stringFromJson(json['profile_id'], fallback: ''),
      voiceProfile: NavivoxProfileVoiceProfile.fromJson(
        _mapFromJson(json['voice_profile']),
      ),
      valid: json['valid'] == true,
      errors: _voiceProfileErrorsFromJson(json['errors']),
      credentialStatusRefs: _voiceCredentialRefsFromJson(
        json['credential_status_refs'],
      ),
    );
  }

  final String profileId;
  final NavivoxProfileVoiceProfile voiceProfile;
  final bool valid;
  final List<NavivoxVoiceProfileFieldError> errors;
  final Map<String, NavivoxVoiceCredentialStatus> credentialStatusRefs;
}

class NavivoxVoiceProfileView {
  const NavivoxVoiceProfileView({
    required this.profileId,
    required this.displayName,
    required this.voiceProfile,
    this.credentialStatusRefs = const {},
    required this.valid,
    this.errors = const [],
  });

  factory NavivoxVoiceProfileView.fromJson(Map<String, Object?> json) {
    final profileId = _stringFromJson(json['profile_id'], fallback: '');
    return NavivoxVoiceProfileView(
      profileId: profileId,
      displayName: _stringFromJson(json['display_name'], fallback: profileId),
      voiceProfile: NavivoxProfileVoiceProfile.fromJson(
        _mapFromJson(json['voice_profile']),
      ),
      credentialStatusRefs: _voiceCredentialRefsFromJson(
        json['credential_status_refs'],
      ),
      valid: json['valid'] == true,
      errors: _voiceProfileErrorsFromJson(json['errors']),
    );
  }

  final String profileId;
  final String displayName;
  final NavivoxProfileVoiceProfile voiceProfile;
  final Map<String, NavivoxVoiceCredentialStatus> credentialStatusRefs;
  final bool valid;
  final List<NavivoxVoiceProfileFieldError> errors;
}

class NavivoxVoiceProfilesResponse {
  const NavivoxVoiceProfilesResponse({
    required this.action,
    required this.providerMatrix,
    this.profiles = const [],
  });

  factory NavivoxVoiceProfilesResponse.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProfilesResponse(
      action: _stringFromJson(json['action'], fallback: ''),
      providerMatrix: NavivoxVoiceProviderMatrix.fromJson(
        _mapFromJson(json['provider_matrix']),
      ),
      profiles: _listFromJson(json['profiles'])
          .whereType<Map>()
          .map(
            (profile) => NavivoxVoiceProfileView.fromJson(
              Map<String, Object?>.from(profile),
            ),
          )
          .toList(growable: false),
    );
  }

  final String action;
  final NavivoxVoiceProviderMatrix providerMatrix;
  final List<NavivoxVoiceProfileView> profiles;
}

class NavivoxVoiceProfileValidationResponse {
  const NavivoxVoiceProfileValidationResponse({
    required this.action,
    required this.providerMatrix,
    this.validation,
    required this.valid,
    this.errors = const [],
  });

  factory NavivoxVoiceProfileValidationResponse.fromJson(
    Map<String, Object?> json,
  ) {
    final validationJson = _mapFromJson(json['validation']);
    final validation = validationJson.isEmpty
        ? null
        : NavivoxVoiceProfileValidation.fromJson(validationJson);
    final topErrors = _voiceProfileErrorsFromJson(json['errors']);
    return NavivoxVoiceProfileValidationResponse(
      action: _stringFromJson(json['action'], fallback: ''),
      providerMatrix: NavivoxVoiceProviderMatrix.fromJson(
        _mapFromJson(json['provider_matrix']),
      ),
      validation: validation,
      valid: json['valid'] == true || validation?.valid == true,
      errors: topErrors.isNotEmpty ? topErrors : validation?.errors ?? const [],
    );
  }

  final String action;
  final NavivoxVoiceProviderMatrix providerMatrix;
  final NavivoxVoiceProfileValidation? validation;
  final bool valid;
  final List<NavivoxVoiceProfileFieldError> errors;
}

class NavivoxConfigAdminField {
  const NavivoxConfigAdminField({
    required this.key,
    required this.type,
    required this.title,
    this.description = '',
    this.secret = false,
    this.allowed = const [],
    this.actions = const [],
    this.reload = '',
  });

  factory NavivoxConfigAdminField.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminField(
      key: _stringFromJson(json['key'] ?? json['path'], fallback: ''),
      type: _stringFromJson(json['type'], fallback: 'string'),
      title: _stringFromJson(
        json['title'] ?? json['label'] ?? json['key'],
        fallback: '',
      ),
      description: _stringFromJson(json['description'], fallback: ''),
      secret: json['secret'] == true,
      allowed: _stringListFromJson(json['allowed']),
      actions: _stringListFromJson(json['actions']),
      reload: _stringFromJson(json['reload'], fallback: ''),
    );
  }

  final String key;
  final String type;
  final String title;
  final String description;
  final bool secret;
  final List<String> allowed;
  final List<String> actions;
  final String reload;

  Map<String, Object?> toFormField() {
    return {
      'key': key,
      'path': key,
      'title': title,
      'label': title,
      'type': type,
      if (description.isNotEmpty) 'description': description,
      if (secret) 'secret': true,
      if (allowed.isNotEmpty) 'allowed': allowed,
      if (actions.isNotEmpty) 'actions': actions,
      if (reload.isNotEmpty) 'reload': reload,
    };
  }
}

class NavivoxConfigAdminSchemaResponse {
  const NavivoxConfigAdminSchemaResponse({
    required this.action,
    this.fields = const [],
  });

  factory NavivoxConfigAdminSchemaResponse.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminSchemaResponse(
      action: _stringFromJson(json['action'], fallback: ''),
      fields: _listFromJson(json['fields'])
          .whereType<Map>()
          .map(
            (field) => NavivoxConfigAdminField.fromJson(
              Map<String, Object?>.from(field),
            ),
          )
          .where((field) => field.key.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String action;
  final List<NavivoxConfigAdminField> fields;

  Map<String, Object?> toConfigSchema() {
    return {'fields': fields.map((field) => field.toFormField()).toList()};
  }
}

class NavivoxConfigAdminValue {
  const NavivoxConfigAdminValue({
    required this.key,
    required this.type,
    this.value,
    this.secret = false,
    this.secretStatus = '',
    this.source = '',
  });

  factory NavivoxConfigAdminValue.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminValue(
      key: _stringFromJson(json['key'] ?? json['path'], fallback: ''),
      type: _stringFromJson(json['type'], fallback: 'string'),
      value: json['value'],
      secret: json['secret'] == true,
      secretStatus: _stringFromJson(json['secret_status'], fallback: ''),
      source: _stringFromJson(json['source'], fallback: ''),
    );
  }

  final String key;
  final String type;
  final Object? value;
  final bool secret;
  final String secretStatus;
  final String source;

  Object? get formValue {
    if (!secret) return value;
    return {
      'secret_status': secretStatus,
      if (source.isNotEmpty) 'source': source,
    };
  }
}

class NavivoxConfigAdminGetResponse {
  const NavivoxConfigAdminGetResponse({
    required this.action,
    this.values = const [],
  });

  factory NavivoxConfigAdminGetResponse.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminGetResponse(
      action: _stringFromJson(json['action'], fallback: ''),
      values: _listFromJson(json['values'])
          .whereType<Map>()
          .map(
            (value) => NavivoxConfigAdminValue.fromJson(
              Map<String, Object?>.from(value),
            ),
          )
          .where((value) => value.key.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String action;
  final List<NavivoxConfigAdminValue> values;

  Map<String, Object?> toConfigValues() {
    return {for (final value in values) value.key: value.formValue};
  }
}

class NavivoxConfigAdminChange {
  const NavivoxConfigAdminChange({
    required this.key,
    required this.value,
    this.delete = false,
  });

  final String key;
  final Object? value;
  final bool delete;

  Map<String, Object?> toJson() {
    final trimmedKey = key.trim();
    return {
      'key': trimmedKey,
      'value': _configAdminWireValue(value),
      if (delete) 'delete': true,
    };
  }
}

class NavivoxConfigAdminDiff {
  const NavivoxConfigAdminDiff({
    required this.key,
    required this.type,
    this.secret = false,
    this.before,
    this.after,
    this.beforeRedacted = false,
    this.afterRedacted = false,
    this.secretStatus = '',
  });

  factory NavivoxConfigAdminDiff.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminDiff(
      key: _stringFromJson(json['key'] ?? json['path'], fallback: ''),
      type: _stringFromJson(json['type'], fallback: 'string'),
      secret: json['secret'] == true,
      before: json['before'],
      after: json['after'],
      beforeRedacted: json['before_redacted'] == true,
      afterRedacted: json['after_redacted'] == true,
      secretStatus: _stringFromJson(json['secret_status'], fallback: ''),
    );
  }

  final String key;
  final String type;
  final bool secret;
  final Object? before;
  final Object? after;
  final bool beforeRedacted;
  final bool afterRedacted;
  final String secretStatus;

  String get summaryLabel {
    return '$key: ${_configAdminDisplayValue(before, redacted: beforeRedacted)} -> ${_configAdminDisplayValue(after, redacted: afterRedacted, secretStatus: secretStatus)}';
  }

  Map<String, Object?> toJson() {
    return {
      'key': key,
      'type': type,
      if (secret) 'secret': true,
      if (!beforeRedacted && before != null) 'before': before,
      if (!afterRedacted && after != null) 'after': after,
      if (beforeRedacted) 'before_redacted': true,
      if (afterRedacted) 'after_redacted': true,
      if (secretStatus.isNotEmpty) 'secret_status': secretStatus,
    };
  }
}

class NavivoxConfigAdminFieldError {
  const NavivoxConfigAdminFieldError({
    required this.key,
    required this.code,
    required this.message,
  });

  factory NavivoxConfigAdminFieldError.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminFieldError(
      key: _stringFromJson(
        json['key'] ?? json['path'] ?? json['field'] ?? json['name'],
        fallback: '',
      ),
      code: _stringFromJson(json['code'], fallback: ''),
      message: _stringFromJson(json['message'] ?? json['error'], fallback: ''),
    );
  }

  final String key;
  final String code;
  final String message;

  Map<String, Object?> toJson() {
    return {'key': key, if (code.isNotEmpty) 'code': code, 'message': message};
  }
}

class NavivoxConfigAdminResponse {
  const NavivoxConfigAdminResponse({
    required this.action,
    required this.valid,
    this.applied = false,
    this.reloadApplied = false,
    this.pendingRestart = false,
    this.reloadError = '',
    this.changes = const [],
    this.errors = const [],
  });

  factory NavivoxConfigAdminResponse.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminResponse(
      action: _stringFromJson(json['action'], fallback: ''),
      valid: json['valid'] == true,
      applied: json['applied'] == true,
      reloadApplied: json['reload_applied'] == true,
      pendingRestart: json['pending_restart'] == true,
      reloadError: _stringFromJson(json['reload_error'], fallback: ''),
      changes: _listFromJson(json['changes'])
          .whereType<Map>()
          .map(
            (change) => NavivoxConfigAdminDiff.fromJson(
              Map<String, Object?>.from(change),
            ),
          )
          .where((change) => change.key.isNotEmpty)
          .toList(growable: false),
      errors: _listFromJson(json['errors'])
          .whereType<Map>()
          .map(
            (error) => NavivoxConfigAdminFieldError.fromJson(
              Map<String, Object?>.from(error),
            ),
          )
          .where((error) => error.key.isNotEmpty || error.message.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String action;
  final bool valid;
  final bool applied;
  final bool reloadApplied;
  final bool pendingRestart;
  final String reloadError;
  final List<NavivoxConfigAdminDiff> changes;
  final List<NavivoxConfigAdminFieldError> errors;

  Map<String, Object?> get snapshot {
    return {
      'action': action,
      'valid': valid,
      if (applied) 'applied': true,
      if (reloadApplied) 'reload_applied': true,
      if (pendingRestart) 'pending_restart': true,
      if (reloadError.isNotEmpty) 'reload_error': reloadError,
      if (changes.isNotEmpty)
        'changes': changes.map((change) => change.toJson()).toList(),
      if (errors.isNotEmpty)
        'errors': errors.map((error) => error.toJson()).toList(),
    };
  }
}

Map<String, NavivoxVoiceCredentialStatus> _voiceCredentialRefsFromJson(
  Object? value,
) {
  if (value is! Map) return const {};
  final refs = <String, NavivoxVoiceCredentialStatus>{};
  for (final entry in value.entries) {
    if (entry.value is Map) {
      refs[entry.key.toString()] = NavivoxVoiceCredentialStatus.fromJson(
        Map<String, Object?>.from(entry.value as Map),
      );
    }
  }
  return refs;
}

List<NavivoxVoiceProfileFieldError> _voiceProfileErrorsFromJson(Object? value) {
  return _listFromJson(value)
      .whereType<Map>()
      .map(
        (error) => NavivoxVoiceProfileFieldError.fromJson(
          Map<String, Object?>.from(error),
        ),
      )
      .toList(growable: false);
}

String _configAdminWireValue(Object? value) {
  if (value == null) return '';
  if (value is Iterable) {
    return value.map((item) => item.toString().trim()).join(',');
  }
  return value.toString().trim();
}

String _configAdminDisplayValue(
  Object? value, {
  bool redacted = false,
  String secretStatus = '',
}) {
  if (redacted) {
    final status = secretStatus.trim();
    return status.isEmpty ? '[redacted]' : '[redacted:$status]';
  }
  if (value == null) return '—';
  if (value is Iterable) return value.join(', ');
  return '$value';
}

String _stringFromJson(Object? value, {required String fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String? _optionalStringFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

int _intFromJson(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is! Map) return const {};
  return Map<String, Object?>.from(value);
}

List<Object?> _listFromJson(Object? value) {
  if (value is! List) return const [];
  return value.cast<Object?>();
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? _dateTimeFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

class NavivoxGatewaySessionSnapshot {
  const NavivoxGatewaySessionSnapshot({
    required this.sessionId,
    required this.lastRequestId,
    required this.profileServer,
    required this.profileId,
    required this.createdAt,
    required this.updatedAt,
    required this.subscribers,
  });

  factory NavivoxGatewaySessionSnapshot.fromJson(Map<String, Object?> json) {
    return NavivoxGatewaySessionSnapshot(
      sessionId: _stringFromJson(json['session_id'], fallback: ''),
      lastRequestId: _stringFromJson(json['last_request_id'], fallback: ''),
      profileServer: _stringFromJson(json['profile_server'], fallback: ''),
      profileId: _stringFromJson(json['profile_id'], fallback: ''),
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
      subscribers: _intFromJson(json['subscribers']),
    );
  }

  final String sessionId;
  final String lastRequestId;
  final String profileServer;
  final String profileId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int subscribers;
}

class NavivoxRunRecordSnapshot {
  const NavivoxRunRecordSnapshot({
    required this.runId,
    required this.sessionId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
    required this.raw,
  });

  factory NavivoxRunRecordSnapshot.fromJson(Map<String, Object?> json) {
    return NavivoxRunRecordSnapshot(
      runId: _stringFromJson(json['run_id'], fallback: ''),
      sessionId: _stringFromJson(json['session_id'], fallback: ''),
      status: _stringFromJson(json['status'], fallback: ''),
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
      completedAt: _dateTimeFromJson(json['completed_at']),
      raw: json,
    );
  }

  final String runId;
  final String sessionId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final Map<String, Object?> raw;
}

class NavivoxProfileSeedResult {
  const NavivoxProfileSeedResult({
    required this.action,
    required this.status,
    required this.applied,
    required this.profileId,
    required this.root,
    required this.workspaceCount,
    required this.draft,
    required this.contact,
  });

  factory NavivoxProfileSeedResult.fromJson(Map<String, Object?> json) {
    return NavivoxProfileSeedResult(
      action: _stringFromJson(json['action'], fallback: ''),
      status: _stringFromJson(json['status'], fallback: ''),
      applied: json['applied'] == true,
      profileId: _stringFromJson(json['profile_id'], fallback: ''),
      root: _stringFromJson(json['root'], fallback: ''),
      workspaceCount: _intFromJson(json['workspace_count']),
      draft: _mapFromJson(json['draft']),
      contact: _mapFromJson(json['contact']),
    );
  }

  final String action;
  final String status;
  final bool applied;
  final String profileId;
  final String root;
  final int workspaceCount;
  final Map<String, Object?> draft;
  final Map<String, Object?> contact;

  bool get isDraft => status == 'draft' && action == 'profile_seed_draft';
  bool get isApplied => applied && action == 'profile_seed_applied';
}

class NavivoxProfileRoutingReport {
  const NavivoxProfileRoutingReport({this.profiles = const []});

  factory NavivoxProfileRoutingReport.fromJson(Map<String, Object?> json) {
    final profiles = json['profiles'];
    return NavivoxProfileRoutingReport(
      profiles: profiles is List
          ? profiles
                .whereType<Map>()
                .map(
                  (profile) => NavivoxProfileRoute.fromJson(
                    Map<String, Object?>.from(profile),
                  ),
                )
                .where((profile) => profile.profileId.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  final List<NavivoxProfileRoute> profiles;
}

class NavivoxProfileRoute {
  const NavivoxProfileRoute({
    required this.profileId,
    required this.displayName,
    this.workspaces = const [],
    this.providers = const [],
    this.channels = const [],
  });

  factory NavivoxProfileRoute.fromJson(Map<String, Object?> json) {
    final profileId = _stringFromJson(json['profile_id'], fallback: '');
    return NavivoxProfileRoute(
      profileId: profileId,
      displayName: _stringFromJson(json['display_name'], fallback: profileId),
      workspaces: _stringListFromJson(json['workspaces']),
      providers: _stringListFromJson(json['providers']),
      channels: _stringListFromJson(json['channels']),
    );
  }

  final String profileId;
  final String displayName;
  final List<String> workspaces;
  final List<String> providers;
  final List<String> channels;
}

class NavivoxGatewayConfig {
  const NavivoxGatewayConfig({
    required this.baseUri,
    this.token,
    this.webSocketUri,
  });

  factory NavivoxGatewayConfig.fromBaseUrl(String baseUrl, {String? token}) {
    return NavivoxGatewayConfig(baseUri: Uri.parse(baseUrl), token: token);
  }

  final Uri baseUri;
  final String? token;
  final Uri? webSocketUri;

  Uri get healthUri => _withPath('/healthz');
  Uri get statusUri => _withPath('/v1/navivox/status');
  Uri get capabilitiesUri => _withPath('/v1/navivox/capabilities');
  Uri get profileContactsUri => _withPath('/v1/navivox/profile-contacts');
  Uri get profileRoutingUri => _withPath('/v1/navivox/profile-routing');
  Uri get profileSeedUri => _withPath('/v1/navivox/profile-seed');
  Uri get configAdminUri => _withPath('/v1/navivox/config-admin');
  Uri get configAdminSchemaUri => _withPath('/v1/navivox/config-admin/schema');
  Uri get configAdminDiffUri => _withPath('/v1/navivox/config-admin/diff');
  Uri get configAdminValidateUri =>
      _withPath('/v1/navivox/config-admin/validate');
  Uri get configAdminApplyUri => _withPath('/v1/navivox/config-admin/apply');
  Uri get voiceProfilesUri => _withPath('/v1/navivox/voice-profiles');
  Uri get voiceProfilesValidateUri =>
      _withPath('/v1/navivox/voice-profiles/validate');
  Uri get memoryActionUri => _withPath('/v1/navivox/memory/action');
  Uri memoryOverviewUri({String? serverId, String? profileId}) {
    final query = <String, String>{
      if (serverId != null && serverId.trim().isNotEmpty)
        'server_id': serverId.trim(),
      if (profileId != null && profileId.trim().isNotEmpty)
        'profile_id': profileId.trim(),
    };
    return _withPath(
      '/v1/navivox/memory/overview',
    ).replace(queryParameters: query.isEmpty ? null : query);
  }

  Uri memorySearchUri({
    String? serverId,
    String? profileId,
    String? query,
    NavivoxMemoryType type = NavivoxMemoryType.all,
    int limit = 20,
    String? pageToken,
  }) {
    final params = <String, String>{
      if (serverId != null && serverId.trim().isNotEmpty)
        'server_id': serverId.trim(),
      if (profileId != null && profileId.trim().isNotEmpty)
        'profile_id': profileId.trim(),
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (type != NavivoxMemoryType.all) 'type': type.wireValue,
      if (limit > 0) 'limit': limit.toString(),
      if (pageToken != null && pageToken.trim().isNotEmpty)
        'page_token': pageToken.trim(),
    };
    return _withPath(
      '/v1/navivox/memory/search',
    ).replace(queryParameters: params.isEmpty ? null : params);
  }

  Uri memoryDetailUri({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  }) {
    final params = <String, String>{
      if (serverId != null && serverId.trim().isNotEmpty)
        'server_id': serverId.trim(),
      if (profileId != null && profileId.trim().isNotEmpty)
        'profile_id': profileId.trim(),
      'id': id.trim(),
      if (type != NavivoxMemoryType.all) 'type': type.wireValue,
    };
    return _withPath(
      '/v1/navivox/memory/detail',
    ).replace(queryParameters: params);
  }

  Uri get sessionsUri => _withPath('/v1/navivox/sessions');
  Uri sessionUri(String sessionId) => _withPath(
    '/v1/navivox/sessions/${Uri.encodeComponent(sessionId.trim())}',
  );
  Uri runRecordUri(String runIdOrSessionId) => _withPath(
    '/v1/navivox/run-records/${Uri.encodeComponent(runIdOrSessionId.trim())}',
  );
  Uri get turnUri => _withPath('/v1/navivox/turn');

  Uri get streamUri {
    final explicit = webSocketUri;
    if (explicit != null) return explicit;
    final scheme = switch (baseUri.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      'wss' || 'ws' => baseUri.scheme,
      _ => 'ws',
    };
    return _withPath('/v1/navivox/stream').replace(scheme: scheme);
  }

  Map<String, String> get headers {
    final value = token?.trim();
    if (value == null || value.isEmpty) {
      return const {};
    }
    return {'Authorization': 'Bearer $value'};
  }

  Uri _withPath(String path) {
    return baseUri.replace(path: path, query: null);
  }
}

class NavivoxPairingDescriptor {
  const NavivoxPairingDescriptor({
    required this.baseUri,
    required this.webSocketUri,
    required this.authMode,
    required this.exposureMode,
    required this.tokenRequired,
    this.token,
    this.serverId,
    this.profileId,
    this.workspaceId,
    this.providerId,
    this.channelIds = const [],
  });

  factory NavivoxPairingDescriptor.parse(String value) {
    final uri = Uri.parse(value.trim());
    if (uri.scheme != 'navivox' || uri.host != 'connect') {
      throw FormatException('Expected navivox://connect descriptor', value);
    }
    final query = uri.queryParameters;
    final tokenRequired = _boolFromPairingParam(query['token_required']);
    final token = _optionalPairingParam(query['rest_token']);
    if (tokenRequired && token == null) {
      throw FormatException('Pairing descriptor requires rest_token', value);
    }
    final webSocketUri = Uri.parse(
      _requiredPairingParam(query, 'websocket_url', value),
    );
    final baseUri = Uri.parse(
      _optionalPairingParam(query['base_url']) ??
          _baseUrlFromWebSocketUri(webSocketUri, value),
    );
    return NavivoxPairingDescriptor(
      baseUri: baseUri,
      webSocketUri: webSocketUri,
      authMode: _optionalPairingParam(query['auth_mode']) ?? '',
      exposureMode: _optionalPairingParam(query['exposure_mode']) ?? '',
      tokenRequired: tokenRequired,
      token: token,
      serverId: _optionalPairingParam(query['server_id']),
      profileId: _optionalPairingParam(query['profile_id']),
      workspaceId: _optionalPairingParam(query['workspace_id']),
      providerId: _optionalPairingParam(query['provider_id']),
      channelIds: _csvPairingParam(query['channel_ids']),
    );
  }

  final Uri baseUri;
  final Uri webSocketUri;
  final String authMode;
  final String exposureMode;
  final bool tokenRequired;
  final String? token;
  final String? serverId;
  final String? profileId;
  final String? workspaceId;
  final String? providerId;
  final List<String> channelIds;

  NavivoxGatewayConfig toGatewayConfig() {
    return NavivoxGatewayConfig(
      baseUri: baseUri,
      token: token,
      webSocketUri: webSocketUri,
    );
  }
}

String _requiredPairingParam(
  Map<String, String> query,
  String name,
  String descriptor,
) {
  final value = _optionalPairingParam(query[name]);
  if (value == null) {
    throw FormatException('Pairing descriptor missing $name', descriptor);
  }
  return value;
}

String? _optionalPairingParam(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _baseUrlFromWebSocketUri(Uri uri, String descriptor) {
  final scheme = switch (uri.scheme.toLowerCase()) {
    'ws' => 'http',
    'wss' => 'https',
    'http' => 'http',
    'https' => 'https',
    _ => throw FormatException(
      'Pairing descriptor invalid websocket_url',
      descriptor,
    ),
  };
  if (uri.host.isEmpty) {
    throw FormatException(
      'Pairing descriptor invalid websocket_url',
      descriptor,
    );
  }
  final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$scheme://$host$port';
}

bool _boolFromPairingParam(String? value) {
  return value?.trim().toLowerCase() == 'true';
}

List<String> _csvPairingParam(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return const [];
  return trimmed
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

class NavivoxGatewayMessage {
  const NavivoxGatewayMessage._(this.body);

  factory NavivoxGatewayMessage.ping({required String requestId}) {
    return NavivoxGatewayMessage._({'type': 'ping', 'request_id': requestId});
  }

  factory NavivoxGatewayMessage.startTurn({
    required String requestId,
    String? sessionId,
    required String text,
    Map<String, Object?> metadata = const {
      'client': 'navivox',
      'platform': 'flutter',
    },
  }) {
    return NavivoxGatewayMessage._({
      'type': 'start_turn',
      'request_id': requestId,
      if (sessionId != null && sessionId.trim().isNotEmpty)
        'session_id': sessionId,
      'text': text,
      'metadata': metadata,
    });
  }

  factory NavivoxGatewayMessage.cancelTurn({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'cancel_turn',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  factory NavivoxGatewayMessage.stopTurn({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'stop_turn',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  factory NavivoxGatewayMessage.subscribeSession({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'subscribe_session',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  final Map<String, Object?> body;
}

class NavivoxGatewayEvent {
  const NavivoxGatewayEvent({
    required this.type,
    this.requestId,
    this.sessionId,
    this.text,
    this.code,
    this.message,
    this.toolName,
    this.toolCallId,
    this.status,
    this.safetyId,
    this.approvalId,
    this.severity,
    this.risk,
    this.runRecordReference,
    this.metadata = const {},
    this.contact,
  });

  factory NavivoxGatewayEvent.fromJson(Map<String, Object?> json) {
    final contact = json['contact'];
    return NavivoxGatewayEvent(
      type: json['type']?.toString() ?? '',
      requestId: json['request_id']?.toString(),
      sessionId: json['session_id']?.toString(),
      text: json['text']?.toString(),
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      toolName: json['tool_name']?.toString(),
      toolCallId: json['tool_call_id']?.toString(),
      status: json['status']?.toString(),
      safetyId: json['safety_id']?.toString(),
      approvalId: json['approval_id']?.toString(),
      severity: json['severity']?.toString(),
      risk: json['risk']?.toString(),
      runRecordReference: _runRecordReferenceFromJson(json),
      metadata: _mapFromJson(json['metadata']),
      contact: contact is Map ? Map<String, Object?>.from(contact) : null,
    );
  }

  final String type;
  final String? requestId;
  final String? sessionId;
  final String? text;
  final String? code;
  final String? message;
  final String? toolName;
  final String? toolCallId;
  final String? status;
  final String? safetyId;
  final String? approvalId;
  final String? severity;
  final String? risk;
  final String? runRecordReference;
  final Map<String, Object?> metadata;
  final Map<String, Object?>? contact;

  bool get isError => type == 'error';
}

String? _runRecordReferenceFromJson(Map<String, Object?> json) {
  return _optionalStringFromJson(json['run_record_ref']) ??
      _optionalStringFromJson(json['run_record_reference']) ??
      _optionalStringFromJson(
        _mapFromJson(json['metadata'])['run_record_ref'],
      ) ??
      _optionalStringFromJson(
        _mapFromJson(json['metadata'])['run_record_reference'],
      );
}
