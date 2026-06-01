import '../../../protocol/config_wire_fields.dart';
import '../../../protocol/navivox_json.dart';
import '../../shared/navivox_gateway_json.dart';
import '../changes/config_admin_value_codec.dart';
import '../status/config_admin_status_fields.dart';
import '../values/config_admin_secret_policy.dart';
import 'config_admin_diff_redaction.dart';

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
    final secret = configAdminIsSecret(json);
    final beforeRedaction = ConfigAdminDiffRedaction(
      isSecret: secret,
      explicitlyRedacted: configAdminStatusBoolFromAliases(
        json,
        configAdminBeforeRedactedAliases,
      ),
      hasRawValue: json.containsKey('before') && json['before'] != null,
    );
    final afterRedaction = ConfigAdminDiffRedaction(
      isSecret: secret,
      explicitlyRedacted: configAdminStatusBoolFromAliases(
        json,
        configAdminAfterRedactedAliases,
      ),
      hasRawValue: json.containsKey('after') && json['after'] != null,
    );

    return NavivoxConfigAdminDiff(
      key: configWireStringFromAliases(json, const ['key', 'path']) ?? '',
      type: configWireString(json['type']) ?? 'string',
      secret: secret,
      before: beforeRedaction.safeValue(json['before']),
      after: afterRedaction.safeValue(json['after']),
      beforeRedacted: beforeRedaction.shouldRedact,
      afterRedacted: afterRedaction.shouldRedact,
      secretStatus: configAdminStatusStringFromAliases(
        json,
        configAdminSecretStatusAliases,
      ),
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

  bool get _isSecret => secret || configAdminTypeIsSecret(type);

  bool get _beforeRedacted => ConfigAdminDiffRedaction(
    isSecret: _isSecret,
    explicitlyRedacted: beforeRedacted,
    hasRawValue: before != null,
  ).shouldRedact;

  bool get _afterRedacted => ConfigAdminDiffRedaction(
    isSecret: _isSecret,
    explicitlyRedacted: afterRedacted,
    hasRawValue: after != null,
  ).shouldRedact;

  String get summaryLabel {
    return '$key: ${configAdminDisplayValue(before, redacted: _beforeRedacted)} -> ${configAdminDisplayValue(after, redacted: _afterRedacted, secretStatus: secretStatus)}';
  }

  Map<String, Object?> toJson() {
    return {
      'key': key,
      'type': type,
      if (_isSecret) 'secret': true,
      if (!_beforeRedacted && before != null) 'before': before,
      if (!_afterRedacted && after != null) 'after': after,
      if (_beforeRedacted) 'before_redacted': true,
      if (_afterRedacted) 'after_redacted': true,
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
      key:
          configWireStringFromAliases(json, const [
            'key',
            'path',
            'field',
            'name',
          ]) ??
          '',
      code: configWireString(json['code']) ?? '',
      message:
          configWireStringFromAliases(json, const ['message', 'error']) ?? '',
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
      action: navivoxStringFieldFromJson(json, 'action'),
      valid: navivoxGatewayBoolField(json, 'valid'),
      applied: navivoxGatewayBoolField(json, 'applied'),
      reloadApplied: configAdminStatusBoolFromAliases(
        json,
        configAdminReloadAppliedAliases,
      ),
      pendingRestart: configAdminStatusBoolFromAliases(
        json,
        configAdminPendingRestartAliases,
      ),
      reloadError: configAdminStatusStringFromAliases(
        json,
        configAdminReloadErrorAliases,
      ),
      changes: navivoxGatewayObjectListWhereHasText(
        json['changes'],
        NavivoxConfigAdminDiff.fromJson,
        (change) => change.key,
      ),
      errors: navivoxGatewayObjectListFromJson(
        json['errors'],
        NavivoxConfigAdminFieldError.fromJson,
        where: (error) =>
            navivoxGatewayHasText(error.key) ||
            navivoxGatewayHasText(error.message),
      ),
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
