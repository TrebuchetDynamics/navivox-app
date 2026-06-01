import '../../protocol/config_wire_fields.dart';

/// Replayable alias contracts for config-admin schema list fields.
///
/// Gateway schema payloads have drifted across snake_case, camelCase, and
/// legacy names. Keeping these aliases named near the schema projection makes
/// dropped list candidates visible in focused tests instead of hiding the
/// fallback order inside DTO construction.
const configAdminSchemaFieldAllowedAliases = configAllowedValuesFieldAliases;

const configAdminSchemaFieldActionAliases = ['actions', 'supported_actions'];

List<String> configAdminSchemaAllowedValues(Map<String, Object?> json) {
  return configWireStringListFromAliases(
    json,
    configAdminSchemaFieldAllowedAliases,
  );
}

List<String> configAdminSchemaActions(Map<String, Object?> json) {
  return configWireStringListFromAliases(
    json,
    configAdminSchemaFieldActionAliases,
  );
}
