Map<String, Object?> configDraftValuesSnapshot(
  Map<String, Object?> draftValues,
) {
  return Map.unmodifiable(Map<String, Object?>.from(draftValues));
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
