import 'config_form_field_type.dart';

Object? coerceConfigEditValue({
  required String raw,
  required ConfigFormFieldType type,
  required bool isSecret,
}) {
  final text = raw.trim();
  if (isSecret) return text;
  return switch (type) {
    ConfigFormFieldType.number => coerceFiniteNumberEditValue(text) ?? raw,
    ConfigFormFieldType.integer => int.tryParse(text) ?? raw,
    ConfigFormFieldType.boolean => coerceBooleanEditValue(text) ?? raw,
    ConfigFormFieldType.string => raw,
    ConfigFormFieldType.secret => text,
  };
}

num? coerceFiniteNumberEditValue(String text) {
  final value = num.tryParse(text);
  if (value == null || !value.isFinite) return null;
  return value;
}

bool? coerceBooleanEditValue(String text) {
  return switch (text.toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}
