import 'navivox_gateway_socket_contract.dart';

class NavivoxGatewaySocket implements NavivoxGatewaySocketConnection {
  @override
  Stream<dynamic> get events => const Stream<dynamic>.empty();

  @override
  void add(String message) {
    throw UnsupportedError('Navivox gateway WebSocket is not supported here.');
  }

  @override
  Future<void> close() async {}
}

Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  throw UnsupportedError('Navivox gateway HTTP is not supported here.');
}

Future<String> defaultPost(Uri uri, Map<String, String> headers, String body) {
  throw UnsupportedError('Navivox gateway HTTP is not supported here.');
}

Future<NavivoxGatewaySocket> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) {
  throw UnsupportedError('Navivox gateway WebSocket is not supported here.');
}
