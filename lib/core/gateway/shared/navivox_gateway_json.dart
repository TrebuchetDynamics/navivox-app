import 'dart:convert';

/// Decodes a gateway response body that must contain a JSON object.
Map<String, Object?> navivoxGatewayDecodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('expected JSON object');
  }
  return Map<String, Object?>.from(decoded);
}

/// Converts a loose gateway JSON value into an object map when possible.
Map<String, Object?>? navivoxGatewayOptionalObjectFromJson(Object? value) {
  if (value is! Map) return null;
  return Map<String, Object?>.from(value);
}

/// Reads a required JSON object field from a decoded gateway response.
Map<String, Object?> navivoxGatewayObjectField(
  Map<String, Object?> body,
  String key,
) {
  final object = navivoxGatewayOptionalObjectFromJson(body[key]);
  if (object == null) {
    throw FormatException('expected JSON object field $key');
  }
  return object;
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
    final object = navivoxGatewayOptionalObjectFromJson(entry.value);
    if (object != null) {
      parsed[entry.key.toString()] = fromJson(object);
    }
  }
  return parsed;
}
