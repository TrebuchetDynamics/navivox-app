import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../support/gateway_routing_test_support.dart';
export '../../support/gateway_routing_test_support.dart' show gatewayTestToken;

typedef GatewayRequestHandler = FutureOr<bool> Function(HttpRequest request);

class ProfileGatewayTestServer {
  ProfileGatewayTestServer._(
    this._server,
    this.port, {
    this.captureStreamMessages = false,
    this.extraHandler,
  });

  final HttpServer _server;
  final int port;
  final bool captureStreamMessages;
  final GatewayRequestHandler? extraHandler;
  final Completer<Map<String, Object?>> _nextClientMessage =
      Completer<Map<String, Object?>>();

  String get baseUrl => 'http://127.0.0.1:$port';

  Future<Map<String, Object?>> get nextClientMessage =>
      _nextClientMessage.future;

  static Future<ProfileGatewayTestServer> start({
    bool captureStreamMessages = false,
    GatewayRequestHandler? extraHandler,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = ProfileGatewayTestServer._(
      server,
      server.port,
      captureStreamMessages: captureStreamMessages,
      extraHandler: extraHandler,
    );
    server.listen(fake._handle);
    return fake;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final handledByExtra = await extraHandler?.call(request);
    if (handledByExtra == true) return;

    if (!isAuthorizedGatewayRequest(request)) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }
    if (request.uri.path == '/v1/navivox/status') {
      writeGatewayJson(request.response, {
        'enabled': true,
        'protocol_version': 'navivox.v1',
        'websocket_protocols': ['navivox.v1'],
        'capabilities': ['profile_contacts', 'profile_routing'],
        'capabilities_url': '/v1/navivox/capabilities',
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/capabilities') {
      writeGatewayJson(request.response, gatewayRoutingCapabilityDocument());
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-contacts') {
      writeGatewayJson(request.response, {
        'contacts': [gormesProfileContact],
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-routing') {
      writeGatewayJson(request.response, {
        'profiles': [gormesProfileRoute],
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/stream') {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((payload) {
        if (captureStreamMessages &&
            !_nextClientMessage.isCompleted &&
            payload is String) {
          _nextClientMessage.complete(
            Map<String, Object?>.from(jsonDecode(payload) as Map),
          );
        }
      });
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }
}
