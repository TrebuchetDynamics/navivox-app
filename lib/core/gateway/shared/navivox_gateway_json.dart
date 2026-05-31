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
