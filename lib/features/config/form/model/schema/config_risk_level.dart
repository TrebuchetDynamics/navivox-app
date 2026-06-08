import '../../config_wire_fields.dart';

const defaultConfigRiskLevel = 'low';
const highConfigRiskLevel = 'high';

String configRiskLevelFromSchema(Map raw) {
  return normalizeConfigRiskLevel(
    configWireStringFromAliases(raw, const ['risk_level']),
  );
}

String normalizeConfigRiskLevel(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return defaultConfigRiskLevel;
  return normalized;
}

bool configRequiresConfirmation({
  required bool explicitRequiresConfirmation,
  required String riskLevel,
}) {
  return explicitRequiresConfirmation ||
      normalizeConfigRiskLevel(riskLevel) == highConfigRiskLevel;
}
