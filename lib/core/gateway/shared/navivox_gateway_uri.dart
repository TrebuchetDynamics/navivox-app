// URI helpers shared by gateway endpoint builders.

/// Adds query parameters to a gateway URI only when at least one parameter is
/// present.
///
/// Endpoint builders use this helper to preserve the gateway's no-empty-query
/// contract: absent optional filters leave the base endpoint unchanged instead
/// of appending a bare `?` or an empty query map.
Uri navivoxGatewayUriWithOptionalQuery(
  Uri uri,
  Map<String, String> queryParameters,
) {
  return uri.replace(
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  );
}

/// Encodes a path segment after applying the gateway's tolerant trim policy.
///
/// Dynamic endpoint segments use trimmed wire IDs before percent-encoding so
/// session and run-record routes cannot drift in whitespace or escaping rules.
String navivoxGatewayTrimmedPathSegment(String value) {
  return Uri.encodeComponent(value.trim());
}
