/// Gateway HTTP header names, values, and status helpers shared by clients and
/// platform transports.
const navivoxGatewayContentTypeHeader = 'Content-Type';

/// JSON media type used for gateway request bodies.
const navivoxGatewayJsonContentType = 'application/json';

/// Returns whether an HTTP status code is successful for gateway transports.
bool navivoxGatewayIsSuccessStatus(int statusCode) {
  return statusCode >= 200 && statusCode < 300;
}

/// Builds the common gateway HTTP failure message used by platform transports.
String navivoxGatewayHttpStatusMessage(Object status) {
  if (status == 413) {
    return 'Navivox gateway rejected the request as too large';
  }
  if (status == 415) {
    return 'Navivox gateway rejected the request content type';
  }
  if (status == 429) {
    return 'Navivox gateway is temporarily rate limiting authentication attempts';
  }
  return 'Navivox gateway returned HTTP $status';
}
