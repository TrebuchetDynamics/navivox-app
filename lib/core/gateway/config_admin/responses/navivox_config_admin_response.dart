import '../../../protocol/config_wire_fields.dart';
import '../../../protocol/navivox_json.dart';
import '../../shared/navivox_gateway_json.dart';
import '../changes/config_admin_value_codec.dart';
import '../status/config_admin_status_fields.dart';

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
      key: configWireStringFromAliases(json, const ['key', 'path']) ?? '',
      type: configWireString(json['type']) ?? 'string',
      secret: navivoxGatewayBoolField(json, 'secret'),
      before: json['before'],
      after: json['after'],
      beforeRedacted: configAdminStatusBoolFromAliases(
        json,
        configAdminBeforeRedactedAliases,
      ),
      afterRedacted: configAdminStatusBoolFromAliases(
        json,
        configAdminAfterRedactedAliases,
      ),
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

  String get summaryLabel {
    return '$key: ${configAdminDisplayValue(before, redacted: beforeRedacted)} -> ${configAdminDisplayValue(after, redacted: afterRedacted, secretStatus: secretStatus)}';
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
