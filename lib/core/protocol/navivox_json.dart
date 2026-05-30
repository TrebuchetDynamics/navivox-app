/// Shared coercion helpers for Navivox wire-protocol JSON payloads.
///
/// These helpers intentionally accept loose `Object?` values because gateway and
/// memory endpoints can be decoded from typed maps, platform channels, or JSON
/// maps with dynamic keys.
String navivoxStringFromJson(Object? value, {required String fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String? navivoxOptionalStringFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

int navivoxIntFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? navivoxDoubleFromJson(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool navivoxBoolFromJson(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

Map<String, Object?> navivoxMapFromJson(Object? value) {
  if (value is! Map) return const {};
  return Map<String, Object?>.from(value);
}

List<Object?> navivoxListFromJson(Object? value) {
  if (value is! List) return const [];
  return value.cast<Object?>();
}

List<String> navivoxStringListFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? navivoxDateTimeFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}
