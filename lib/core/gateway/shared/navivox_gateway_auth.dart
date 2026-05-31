import 'dart:convert';

import 'navivox_gateway_constants.dart';

/// Gateway HTTP authorization header name used by REST and stream setup.
const navivoxGatewayAuthorizationHeader = 'Authorization';

const _bearerPrefix = 'Bearer ';

/// Builds the gateway's bearer authorization header value from a raw token.
String navivoxGatewayBearerAuthorization(String token) {
  return '$_bearerPrefix${token.trim()}';
}

/// Extracts a bearer token from gateway headers using case-insensitive names.
String? navivoxGatewayBearerToken(Map<String, String> headers) {
  final auth = headers.entries
      .where(
        (entry) =>
            entry.key.toLowerCase() ==
            navivoxGatewayAuthorizationHeader.toLowerCase(),
      )
      .map((entry) => entry.value.trim())
      .firstOrNull;
  if (auth == null || !auth.startsWith(_bearerPrefix)) return null;
  return auth.substring(_bearerPrefix.length).trim();
}

/// Builds WebSocket subprotocols accepted by the gateway.
///
/// Browsers cannot set arbitrary WebSocket headers, so bearer auth is carried
/// as a gateway-specific subprotocol while retaining the base Navivox protocol.
List<String> navivoxGatewayWebSocketProtocols(Map<String, String> headers) {
  final protocols = <String>[navivoxWebSocketProtocol];
  final token = navivoxGatewayBearerToken(headers);
  if (token != null && token.isNotEmpty) {
    protocols.add(
      '$navivoxWebSocketTokenProtocolPrefix'
      '${base64Url.encode(utf8.encode(token)).replaceAll('=', '')}',
    );
  }
  return protocols;
}
