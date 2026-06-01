import '../../../protocol/config_wire_fields.dart';

/// Replayable alias contracts for config-admin status/redaction fields.
///
/// Gateway config-admin payloads may arrive from Python dicts, JSON snapshots,
/// or UI replay fixtures using either snake_case or camelCase names. Keeping the
/// accepted aliases explicit prevents secret redaction and reload evidence from
/// being dropped by parser-local exact-key lookups.
const configAdminSecretStatusAliases = ['secret_status', 'secretStatus'];
const configAdminBeforeRedactedAliases = ['before_redacted', 'beforeRedacted'];
const configAdminAfterRedactedAliases = ['after_redacted', 'afterRedacted'];
const configAdminReloadAppliedAliases = ['reload_applied', 'reloadApplied'];
const configAdminPendingRestartAliases = ['pending_restart', 'pendingRestart'];
const configAdminReloadErrorAliases = ['reload_error', 'reloadError'];

String configAdminStatusStringFromAliases(
  Map<String, Object?> json,
  Iterable<String> aliases,
) {
  return configWireStringFromAliases(json, aliases) ?? '';
}

bool configAdminStatusBoolFromAliases(
  Map<String, Object?> json,
  Iterable<String> aliases,
) {
  return configWireBoolFromAliases(json, aliases) ?? false;
}
