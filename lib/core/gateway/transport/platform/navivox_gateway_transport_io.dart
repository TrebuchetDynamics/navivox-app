import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../shared/navivox_gateway_auth.dart';
import '../../shared/navivox_gateway_http.dart';
import '../navivox_gateway_socket_contract.dart';

/// Dart VM HTTP GET transport for the Navivox gateway.
Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  return _request(uri: uri, method: 'GET', headers: headers);
}

/// Dart VM HTTP POST transport for the Navivox gateway.
Future<String> defaultPost(Uri uri, Map<String, String> headers, String body) {
  return _request(uri: uri, method: 'POST', headers: headers, body: body);
}

Future<String> _request({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    final payload = body;
    if (payload != null) {
      request.write(payload);
    }
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    if (!navivoxGatewayIsSuccessStatus(response.statusCode)) {
      throw HttpException(
        navivoxGatewayHttpStatusMessage(response.statusCode),
        uri: uri,
      );
    }
    return responseBody;
  } finally {
    client.close(force: true);
  }
}

/// Dart VM WebSocket connector for the Navivox gateway stream.
Future<NavivoxGatewaySocketConnection> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) async {
  final webSocketHeaders = <String, String>{...headers}
    ..removeWhere(
      (name, _) =>
          name.toLowerCase() == navivoxGatewayAuthorizationHeader.toLowerCase(),
    );
  try {
    final socket = await WebSocket.connect(
      uri.toString(),
      headers: webSocketHeaders,
      protocols: navivoxGatewayWebSocketProtocols(headers),
    );
    return NavivoxGatewaySocket(socket);
  } on WebSocketException catch (error) {
    final statusCode = _navivoxWebSocketHandshakeStatusCode(error);
    if (statusCode != null) {
      throw HttpException(
        navivoxGatewayHttpStatusMessage(statusCode),
        uri: uri,
      );
    }
    rethrow;
  }
}

int? _navivoxWebSocketHandshakeStatusCode(WebSocketException error) {
  final match = RegExp(
    r'HTTP status code:\s*(\d{3})',
  ).firstMatch(error.toString());
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Dart VM socket wrapper matching the gateway socket contract.
class NavivoxGatewaySocket implements NavivoxGatewaySocketConnection {
  NavivoxGatewaySocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get events => _socket;

  @override
  void add(String message) {
    _socket.add(message);
  }

  @override
  Future<void> close() {
    return _socket.close();
  }
}
