/// Hermes API HTTP header names, values, and status helpers.
const hermesApiAuthorizationHeader = 'Authorization';
const hermesApiContentTypeHeader = 'Content-Type';
const hermesApiAcceptHeader = 'Accept';
const hermesApiCacheControlHeader = 'Cache-Control';
const hermesApiJsonContentType = 'application/json';
const hermesApiEventStreamContentType = 'text/event-stream';
const hermesApiNoCache = 'no-cache';

String hermesApiBearerAuthorization(String apiKey) {
  final trimmed = apiKey.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(apiKey, 'apiKey', 'must not be blank');
  }
  return 'Bearer $trimmed';
}

bool hermesApiIsSuccessStatus(int statusCode) {
  return statusCode >= 200 && statusCode < 300;
}

String hermesApiHttpStatusMessage(Object status) {
  if (status == 401 || status == 403) {
    return 'Hermes API rejected the request credentials';
  }
  if (status == 429) {
    return 'Hermes API is temporarily rate limiting requests';
  }
  return 'Hermes API returned HTTP $status';
}
