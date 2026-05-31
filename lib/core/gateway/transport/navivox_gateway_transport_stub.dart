import 'navivox_gateway_socket_contract.dart';
import 'navivox_gateway_transport_errors.dart';

class NavivoxGatewaySocket implements NavivoxGatewaySocketConnection {
  @override
  Stream<dynamic> get events => const Stream<dynamic>.empty();

  @override
  void add(String message) {
    throw navivoxGatewayUnsupportedWebSocket();
  }

  @override
  Future<void> close() async {}
}

Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  throw navivoxGatewayUnsupportedHttp();
}

Future<String> defaultPost(Uri uri, Map<String, String> headers, String body) {
  throw navivoxGatewayUnsupportedHttp();
}

Future<NavivoxGatewaySocket> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) {
  throw navivoxGatewayUnsupportedWebSocket();
}
