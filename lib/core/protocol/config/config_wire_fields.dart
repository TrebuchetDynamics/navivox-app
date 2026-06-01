import '../serialization/navivox_json.dart';

/// Shared helpers for loose config-schema/validation wire maps.
///
/// Gormes config payloads may identify fields with related aliases depending on
/// whether the source is schema rows, validation errors, or section references.
/// These helpers keep alias lookup and non-empty string coercion consistent
/// across gateway protocol models and UI form models without broadening each
/// call site's accepted aliases.
const configAllowedValuesFieldAliases = [
  'allowed',
  'allowed_values',
  'enum_values',
  'choices',
  'options',
];

String? configWireString(Object? raw) => navivoxOptionalStringFromJson(raw);

Object? configWireValueFromAliases(Map raw, Iterable<String> aliases) {
  for (final value in configWireAliasCandidates(raw, aliases)) {
    if (value != null) return value;
  }
  return null;
}

/// Returns the first non-empty alias value.
///
/// Use this for collection-shaped aliases where an empty preferred alias should
/// not suppress a later populated compatibility alias from the same payload.
Object? configWirePopulatedValueFromAliases(Map raw, Iterable<String> aliases) {
  for (final value in configWireAliasCandidates(raw, aliases)) {
    if (_configWireValueIsPopulated(value)) return value;
  }
  return null;
}

String? configWireStringFromAliases(Map raw, Iterable<String> aliases) {
  for (final value in configWireAliasCandidates(raw, aliases)) {
    final text = configWireString(value);
    if (text != null) return text;
  }
  return null;
}

List<String> configWireStringListFromAliases(
  Map raw,
  Iterable<String> aliases,
) {
  for (final value in configWireAliasCandidates(raw, aliases)) {
    final list = navivoxStringListFromJson(value);
    if (list.isNotEmpty) return list;
  }
  return const [];
}

bool? configWireBoolFromAliases(Map raw, Iterable<String> aliases) {
  for (final value in configWireAliasCandidates(raw, aliases)) {
    if (value is bool) return value;
  }
  return null;
}

/// Replays loose config wire alias lookup in parsing order.
///
/// Exact aliases are considered first in caller-provided order. Canonical
/// compatibility spellings (for example camelCase versus snake_case) are then
/// considered in source map order, excluding exact keys that were already
/// yielded. Keeping this as a pure helper makes field provenance replayable in
/// tests instead of hiding dropped or fallback candidates inside each parser.
Iterable<Object?> configWireAliasCandidates(
  Map raw,
  Iterable<String> aliases,
) sync* {
  final exactAliases = aliases.toSet();
  final yieldedKeys = <Object?>{};
  for (final alias in exactAliases) {
    if (!raw.containsKey(alias)) continue;
    yieldedKeys.add(alias);
    yield raw[alias];
  }

  final normalizedAliases = {
    for (final alias in exactAliases) _configNormalizeWireFieldName(alias),
  };
  for (final entry in raw.entries) {
    if (yieldedKeys.contains(entry.key)) continue;
    if (normalizedAliases.contains(
      _configNormalizeWireFieldName('${entry.key}'),
    )) {
      yield entry.value;
    }
  }
}

bool _configWireValueIsPopulated(Object? value) {
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

String _configNormalizeWireFieldName(String value) =>
    value.toLowerCase().replaceAll('_', '');
