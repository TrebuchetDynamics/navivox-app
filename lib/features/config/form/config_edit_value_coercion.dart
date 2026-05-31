import 'config_form_field_type.dart';

Object? coerceConfigEditValue({
  required String raw,
  required ConfigFormFieldType type,
  required bool isSecret,
}) {
  final text = raw.trim();
  if (isSecret) return text;
  return switch (type) {
    ConfigFormFieldType.number => num.tryParse(text) ?? raw,
    ConfigFormFieldType.integer => int.tryParse(text) ?? raw,
    ConfigFormFieldType.boolean => coerceBooleanEditValue(text) ?? raw,
    ConfigFormFieldType.string => raw,
    ConfigFormFieldType.secret => text,
  };
}

bool? coerceBooleanEditValue(String text) {
  return switch (text.toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}
