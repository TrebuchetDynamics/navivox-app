Map<String, Object?> configDraftValuesSnapshot(
  Map<String, Object?> draftValues,
) {
  return Map.unmodifiable({
    for (final entry in draftValues.entries)
      entry.key: configDraftValueSnapshot(entry.value),
  });
}

Object? configDraftValueSnapshot(Object? value) {
  if (value is Map) {
    return Map.unmodifiable({
      for (final entry in value.entries)
        entry.key: configDraftValueSnapshot(entry.value),
    });
  }
  if (value is List) {
    return List.unmodifiable(value.map(configDraftValueSnapshot));
  }
  if (value is Set) {
    return Set.unmodifiable(value.map(configDraftValueSnapshot));
  }
  return value;
}

bool configDraftValuesContainsSameEntry({
  required Map<String, Object?> draftValues,
  required String path,
  required Object? appliedValue,
  required bool Function(Object? left, Object? right) valuesEqual,
}) {
  return draftValues.containsKey(path) &&
      valuesEqual(draftValues[path], appliedValue);
}
