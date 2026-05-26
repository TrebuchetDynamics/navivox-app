import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway_navivox_channel.dart';

void main() {
  test(
    'connect loads Gormes profile routing choices when advertised',
    () async {
      final server = await _ProfileRoutingGateway.start();
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(
        baseUrl: server.baseUrl,
        token: _ProfileRoutingGateway.token,
      );

      expect(channel.state.profileRouting.profiles, hasLength(1));
      final route = channel.state.profileRouting.profiles.single;
      expect(route.profileId, 'mineru');
      expect(route.displayName, 'Mineru Ops');
      expect(route.workspaces, ['/srv/gormes', '/srv/navivox']);
      expect(route.providers, ['openai-codex', 'ollama']);
      expect(route.channels, ['navivox', 'telegram']);
      expect(channel.state.activeProfileRoute?.profileId, 'mineru');
    },
  );
}

class _ProfileRoutingGateway {
  _ProfileRoutingGateway._(this._server, this.port);

  static const token = 'nvbx_test_token';

  final HttpServer _server;
  final int port;

  String get baseUrl => 'http://127.0.0.1:$port';

  static Future<_ProfileRoutingGateway> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _ProfileRoutingGateway._(server, server.port);
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
        'capabilities_url': '/v1/navivox/capabilities',
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/capabilities') {
      _writeJson(request.response, _capabilityDocument());
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
      socket.listen((_) {});
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Map<String, Object?> _capabilityDocument() {
    return {
      'object': 'gormes.navivox.capabilities',
      'protocol_version': 'navivox.v1',
      'capabilities': ['profile_contacts', 'profile_routing', 'stream_turns'],
      'auth': {
        'mode': 'pairing_token',
        'headers': ['Authorization: Bearer <token>'],
        'websocket_protocols': ['navivox.v1'],
      },
      'health': {
        'canonical': '/healthz',
        'aliases': ['/healthz'],
        'auth': 'none',
      },
      'endpoints': [
        {
          'method': 'GET',
          'path': '/v1/navivox/capabilities',
          'auth': 'navivox',
          'stability': 'stable',
          'description': 'Capability document',
        },
        {
          'method': 'GET',
          'path': '/v1/navivox/profile-contacts',
          'auth': 'navivox',
          'stability': 'stable',
          'description': 'Profile contacts',
        },
        {
          'method': 'GET',
          'path': '/v1/navivox/profile-routing',
          'auth': 'navivox',
          'stability': 'stable',
          'description': 'Profile routing',
        },
        {
          'method': 'WS',
          'path': '/v1/navivox/stream',
          'auth': 'navivox',
          'stability': 'stable',
          'description': 'Navivox stream',
        },
      ],
      'profile_management': {
        'contacts_endpoint': '/v1/navivox/profile-contacts',
        'routing_endpoint': '/v1/navivox/profile-routing',
        'create_from_seed_endpoint': '/v1/navivox/profile-seed',
        'dashboard_api_exposed': false,
        'supported_actions': ['contact_snapshot'],
        'unsupported_actions': ['direct_dashboard_api_profiles'],
        'profile_contract_parts': ['profile_contacts', 'profile_routing'],
      },
      'attachments': {
        'max_request_bytes': 1048576,
        'opaque_upload_ids': false,
        'raw_local_paths_accepted': false,
        'workspace_file_attach': false,
        'mime_allowlist': <String>[],
        'retention': 'not_accepted',
      },
      'voice': {
        'device_transcribed_text_turns': true,
        'raw_audio_upload': false,
        'voice_profiles_endpoint': '/v1/navivox/voice-profiles',
        'run_records_endpoint':
            '/v1/navivox/run-records/{run_id_or_session_id}',
        'stt_providers': ['device'],
        'tts_providers': ['server'],
      },
      'streams': {
        'canonical_endpoint': '/v1/navivox/stream',
        'transport': 'websocket',
        'event_kinds': ['session_started', 'assistant_message', 'done'],
        'openai_runs_bridge': false,
      },
    };
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
