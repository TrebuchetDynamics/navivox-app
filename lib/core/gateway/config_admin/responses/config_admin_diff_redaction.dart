/// Replayable redaction decision for one config-admin diff value.
///
/// Diff payloads can be produced by older gateways that mark secret fields only
/// through `type: secret`, or by buggy gateways that echo raw secret values
/// without the matching `*_redacted` flag. Keeping the decision as a value type
/// makes the privacy invariant testable separately from DTO parsing.
class ConfigAdminDiffRedaction {
  const ConfigAdminDiffRedaction({
    required this.isSecret,
    required this.explicitlyRedacted,
    required this.hasRawValue,
  });

  final bool isSecret;
  final bool explicitlyRedacted;
  final bool hasRawValue;

  bool get shouldRedact => explicitlyRedacted || (isSecret && hasRawValue);

  Object? safeValue(Object? value) => shouldRedact ? null : value;
}
