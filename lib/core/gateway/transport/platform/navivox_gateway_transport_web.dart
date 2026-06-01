import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../shared/navivox_gateway_auth.dart';
import '../../shared/navivox_gateway_http.dart';
import '../navivox_gateway_socket_contract.dart';

/// Browser HTTP GET transport for the Navivox gateway.
Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  return _request(uri: uri, method: 'GET', headers: headers);
}

/// Browser HTTP POST transport for the Navivox gateway.
Future<String> defaultPost(Uri uri, Map<String, String> headers, String body) {
  return _request(uri: uri, method: 'POST', headers: headers, body: body);
}

Future<String> _request({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) async {
  final request = web.XMLHttpRequest();
  final completer = Completer<String>();

  request.open(method, uri.toString(), true);
  headers.forEach(request.setRequestHeader);
  request.onLoad.listen((_) {
    final status = request.status;
    if (navivoxGatewayIsSuccessStatus(status)) {
      completer.complete(request.responseText);
    } else {
      completer.completeError(
        StateError(navivoxGatewayHttpStatusMessage(status)),
      );
    }
  });
  request.onError.listen(
    (_) => completer.completeError(
      StateError(navivoxGatewayHttpStatusMessage(request.status)),
    ),
  );

  final payload = body;
  if (payload == null) {
    request.send();
  } else {
    request.send(payload.toJS);
  }
  return completer.future;
}

/// Browser WebSocket connector for the Navivox gateway stream.
Future<NavivoxGatewaySocketConnection> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) async {
  return NavivoxGatewaySocket(
    web.WebSocket(
      uri.toString(),
      navivoxGatewayWebSocketProtocols(
        headers,
      ).map((protocol) => protocol.toJS).toList().toJS,
    ),
  );
}

/// Browser socket wrapper matching the gateway socket contract.
class NavivoxGatewaySocket implements NavivoxGatewaySocketConnection {
  NavivoxGatewaySocket(this._socket);

  final web.WebSocket _socket;

  @override
  Stream<dynamic> get events =>
      _socket.onMessage.map((event) => event.data.dartify());

  @override
  void add(String message) {
    _socket.send(message.toJS);
  }

  @override
  Future<void> close() async {
    _socket.close();
  }
}
