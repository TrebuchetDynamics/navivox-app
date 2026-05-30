import '../../protocol/navivox_json.dart';

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
      key: navivoxStringFromJson(json['key'] ?? json['path'], fallback: ''),
      type: navivoxStringFromJson(json['type'], fallback: 'string'),
      title: navivoxStringFromJson(
        json['title'] ?? json['label'] ?? json['key'],
        fallback: '',
      ),
      description: navivoxStringFromJson(json['description'], fallback: ''),
      secret: json['secret'] == true,
      allowed: navivoxStringListFromJson(json['allowed']),
      actions: navivoxStringListFromJson(json['actions']),
      reload: navivoxStringFromJson(json['reload'], fallback: ''),
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
      action: navivoxStringFromJson(json['action'], fallback: ''),
      fields: navivoxListFromJson(json['fields'])
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
      key: navivoxStringFromJson(json['key'] ?? json['path'], fallback: ''),
      type: navivoxStringFromJson(json['type'], fallback: 'string'),
      value: json['value'],
      secret: json['secret'] == true,
      secretStatus: navivoxStringFromJson(json['secret_status'], fallback: ''),
      source: navivoxStringFromJson(json['source'], fallback: ''),
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
      action: navivoxStringFromJson(json['action'], fallback: ''),
      values: navivoxListFromJson(json['values'])
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
      key: navivoxStringFromJson(json['key'] ?? json['path'], fallback: ''),
      type: navivoxStringFromJson(json['type'], fallback: 'string'),
      secret: json['secret'] == true,
      before: json['before'],
      after: json['after'],
      beforeRedacted: json['before_redacted'] == true,
      afterRedacted: json['after_redacted'] == true,
      secretStatus: navivoxStringFromJson(json['secret_status'], fallback: ''),
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
      key: navivoxStringFromJson(
        json['key'] ?? json['path'] ?? json['field'] ?? json['name'],
        fallback: '',
      ),
      code: navivoxStringFromJson(json['code'], fallback: ''),
      message: navivoxStringFromJson(
        json['message'] ?? json['error'],
        fallback: '',
      ),
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
      action: navivoxStringFromJson(json['action'], fallback: ''),
      valid: json['valid'] == true,
      applied: json['applied'] == true,
      reloadApplied: json['reload_applied'] == true,
      pendingRestart: json['pending_restart'] == true,
      reloadError: navivoxStringFromJson(json['reload_error'], fallback: ''),
      changes: navivoxListFromJson(json['changes'])
          .whereType<Map>()
          .map(
            (change) => NavivoxConfigAdminDiff.fromJson(
              Map<String, Object?>.from(change),
            ),
          )
          .where((change) => change.key.isNotEmpty)
          .toList(growable: false),
      errors: navivoxListFromJson(json['errors'])
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
