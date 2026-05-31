import '../serialization/navivox_json.dart';

/// Shared memory-protocol degradation contract.
///
/// Memory overview, search, detail, and action payloads all surface degraded
/// state through the same wire aliases and non-empty reason semantics.
String navivoxMemoryDegradedReasonFromJson(Map<String, Object?> json) {
  return navivoxStringFromJson(
    json['degraded_reason'] ?? json['reason'],
    fallback: '',
  );
}

bool navivoxMemoryIsDegraded(String degradedReason) {
  return degradedReason.trim().isNotEmpty;
}
