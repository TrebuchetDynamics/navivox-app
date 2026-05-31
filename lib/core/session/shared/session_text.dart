bool isNonBlankSessionText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

String requiredSessionText(String? value, {required String fieldName}) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must be non-blank');
  }
  return text;
}
