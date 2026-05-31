// URI helpers shared by gateway endpoint builders.

/// Encodes a path segment after applying the gateway's tolerant trim policy.
///
/// Dynamic endpoint segments use trimmed wire IDs before percent-encoding so
/// session and run-record routes cannot drift in whitespace or escaping rules.
String navivoxGatewayTrimmedPathSegment(String value) {
  return Uri.encodeComponent(value.trim());
}
