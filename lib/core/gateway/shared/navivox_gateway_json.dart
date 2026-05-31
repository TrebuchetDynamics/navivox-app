import 'dart:convert';

/// Decodes a gateway response body that must contain a JSON object.
Map<String, Object?> navivoxGatewayDecodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('expected JSON object');
  }
  return Map<String, Object?>.from(decoded);
}

/// Reads a required JSON object field from a decoded gateway response.
Map<String, Object?> navivoxGatewayObjectField(
  Map<String, Object?> body,
  String key,
) {
  final value = body[key];
  if (value is! Map) {
    throw FormatException('expected JSON object field $key');
  }
  return Map<String, Object?>.from(value);
}

/// Parses a loose gateway JSON object whose values are nested objects.
///
/// Non-map values are ignored so optional reference maps can tolerate forward
/// compatible wire payloads without each parser reimplementing the same loop.
Map<String, T> navivoxGatewayObjectValueMapFromJson<T>(
  Object? value,
  T Function(Map<String, Object?> json) fromJson,
) {
  if (value is! Map) return const {};
  final parsed = <String, T>{};
  for (final entry in value.entries) {
    if (entry.value is Map) {
      parsed[entry.key.toString()] = fromJson(
        Map<String, Object?>.from(entry.value as Map),
      );
    }
  }
  return parsed;
}
