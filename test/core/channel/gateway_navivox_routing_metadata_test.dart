import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway_navivox_channel.dart';

void main() {
  test('selected profile routing is included in start turn metadata', () async {
    final server = await _RoutingMetadataGateway.start();
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(
      baseUrl: server.baseUrl,
      token: _RoutingMetadataGateway.token,
    );
    channel.selectProfileRouting(
      workspace: '/srv/navivox',
      provider: 'ollama',
      channel: 'telegram',
    );

    channel.sendText('use the selected route');

    final sent = await server.nextClientMessage;
    final metadata = Map<String, Object?>.from(sent['metadata'] as Map);
    expect(metadata['server_id'], 'local-gormes');
    expect(metadata['profile_id'], 'mineru');
    expect(metadata['workspace'], '/srv/navivox');
    expect(metadata['provider_id'], 'ollama');
    expect(metadata['channel_id'], 'telegram');
  });
}

class _RoutingMetadataGateway {
  _RoutingMetadataGateway._(this._server, this.port);

  static const token = 'nvbx_test_token';

  final HttpServer _server;
  final int port;
  final Completer<Map<String, Object?>> _nextClientMessage =
      Completer<Map<String, Object?>>();

  String get baseUrl => 'http://127.0.0.1:$port';
  Future<Map<String, Object?>> get nextClientMessage =>
      _nextClientMessage.future;

  static Future<_RoutingMetadataGateway> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _RoutingMetadataGateway._(server, server.port);
    server.listen(fake._handle);
    return fake;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    if (!_authorized(request)) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }
    if (request.uri.path == '/v1/navivox/status') {
      _writeJson(request.response, {
        'enabled': true,
        'protocol_version': 'navivox.v1',
        'websocket_protocols': ['navivox.v1'],
        'capabilities': ['profile_contacts', 'profile_routing'],
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-contacts') {
      _writeJson(request.response, {
        'contacts': [
          {
            'server_id': 'local-gormes',
            'profile_id': 'mineru',
            'display_name': 'Mineru Ops',
            'server_label': 'local',
            'health': 'online',
            'latest_preview': 'Gateway online',
            'latest_preview_kind': 'status',
            'workspace_root_count': 2,
            'workspace_roots_ok': true,
            'workspace_roots_warning': 0,
            'workspace_roots_error': 0,
            'attention_badges': <String>[],
            'mic_available': true,
            'active_turn_state': 'idle',
          },
        ],
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-routing') {
      _writeJson(request.response, {
        'profiles': [
          {
            'profile_id': 'mineru',
            'display_name': 'Mineru Ops',
            'workspaces': ['/srv/gormes', '/srv/navivox'],
            'providers': ['openai-codex', 'ollama'],
            'channels': ['navivox', 'telegram'],
          },
        ],
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/stream') {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((payload) {
        if (!_nextClientMessage.isCompleted && payload is String) {
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

  bool _authorized(HttpRequest request) {
    return request.headers.value(HttpHeaders.authorizationHeader) ==
        'Bearer $token';
  }

  void _writeJson(HttpResponse response, Map<String, Object?> body) {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    unawaited(response.close());
  }
}
