// URI helpers shared by gateway endpoint builders.

/// Builds a gateway endpoint URI from the configured origin and a canonical path.
///
/// `Uri.replace(query: null)` keeps the previous query/fragment, so endpoint
/// builders use this explicit constructor to avoid leaking pairing/setup query
/// state or userinfo credentials into every gateway request.
Uri navivoxGatewayEndpointUri(Uri baseUri, String path) {
  return Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.hasPort ? baseUri.port : null,
    path: path,
  );
}

/// Scrubs an explicit WebSocket endpoint down to scheme/host/port/path.
///
/// Explicit WebSocket URLs can arrive from setup handoff or manual entry. The
/// gateway never accepts URL credentials, so clients strip userinfo, query, and
/// fragments before opening a stream.
Uri navivoxGatewayWebSocketEndpointUri(Uri uri) {
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path.isEmpty ? '/v1/navivox/stream' : uri.path,
  );
}

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

/// Returns a trimmed required gateway value or fails before an ambiguous call.
///
/// Required dynamic IDs must not collapse to empty strings because that can
/// turn a detail/action request into a collection-like endpoint or an empty
/// query field whose failing resource is no longer replayable from the URI.
String navivoxGatewayRequiredTrimmedValue(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return trimmed;
}

/// Encodes a path segment after applying the gateway's tolerant trim policy.
///
/// Dynamic endpoint segments use trimmed wire IDs before percent-encoding so
/// session and run-record routes cannot drift in whitespace or escaping rules.
String navivoxGatewayTrimmedPathSegment(String value, {String name = 'value'}) {
  return Uri.encodeComponent(navivoxGatewayRequiredTrimmedValue(value, name));
}
