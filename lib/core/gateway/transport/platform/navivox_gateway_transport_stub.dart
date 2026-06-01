import 'dart:async';

import '../navivox_gateway_socket_contract.dart';
import '../navivox_gateway_transport_errors.dart';

/// Unsupported HTTP GET transport used when no platform transport is available.
Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  throw navivoxGatewayUnsupportedHttp();
}

/// Unsupported HTTP POST transport used when no platform transport is available.
Future<String> defaultPost(Uri uri, Map<String, String> headers, String body) {
  throw navivoxGatewayUnsupportedHttp();
}

/// Unsupported WebSocket transport used when no platform transport is available.
Future<NavivoxGatewaySocketConnection> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) {
  throw navivoxGatewayUnsupportedWebSocket();
}

/// Socket wrapper that preserves the historical stub constructor contract.
class NavivoxGatewaySocket implements NavivoxGatewaySocketConnection {
  const NavivoxGatewaySocket();

  @override
  Stream<dynamic> get events => const Stream<dynamic>.empty();

  @override
  void add(String message) {
    throw navivoxGatewayUnsupportedWebSocket();
  }

  @override
  Future<void> close() {
    throw navivoxGatewayUnsupportedWebSocket();
  }
}
