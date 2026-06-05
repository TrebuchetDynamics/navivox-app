import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway_navivox_channel.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/core/session/session_persistence_service.dart';

import '../core/session/support/session_persistence_test_support.dart';

void main() {
  setUp(() {
    resetSessionPreferences();
  });

  test('gateway client e2e decodes authenticated transport security', () async {
    final server = await _IdentityGatewayServer.start();
    addTearDown(server.close);

    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        server.baseUrl,
        token: 'nvbx_test_token',
      ),
    );

    final status = await client.gatewayStatus();

    expect(status.gatewayId, 'gw_0123456789abcdef0123456789abcdef');
    expect(status.transportSecurity.effectiveSecurity, 'loopback');
    expect(status.transportSecurity.exposureMode, 'local');
    expect(status.transportSecurity.tls, isFalse);
    expect(status.transportSecurity.privateNetwork, isFalse);
    expect(status.transportSecurity.durableCredentialsAllowed, isFalse);
  });

  test('gateway client e2e surfaces auth rate limiting', () async {
    final server = await _IdentityGatewayServer.start(rateLimitStatus: true);
    addTearDown(server.close);

    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        server.baseUrl,
        token: 'nvbx_test_token',
      ),
    );

    await expectLater(
      client.gatewayStatus(),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'Navivox gateway is temporarily rate limiting authentication attempts',
        ),
      ),
    );
  });

  test('gateway client e2e surfaces unsupported media type', () async {
    final server = await _IdentityGatewayServer.start(
      unsupportedMediaStatus: true,
    );
    addTearDown(server.close);

    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        server.baseUrl,
        token: 'nvbx_test_token',
      ),
    );

    await expectLater(
      client.gatewayStatus(),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'Navivox gateway rejected the request content type',
        ),
      ),
    );
  });

  test('gateway client e2e refuses authenticated HTTP redirects', () async {
    final server = await _IdentityGatewayServer.start(redirectStatus: true);
    addTearDown(server.close);

    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        server.baseUrl,
        token: 'nvbx_test_token',
      ),
    );

    await expectLater(
      client.gatewayStatus(),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'Navivox gateway returned HTTP 302',
        ),
      ),
    );
    expect(server.redirectAuthorizationHeaders, isEmpty);
  });

  test(
    'gateway channel e2e blocks oversized stream turn before send',
    () async {
      final server = await _IdentityGatewayServer.start(
        streamAvailable: true,
        maxRequestBytes: 128,
      );
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: 'nvbx_test_token');

      channel.sendText('x' * 512);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(server.streamMessages, isEmpty);
      expect(channel.state.messagesList.last.text, contains('too large'));
    },
  );

  test('gateway client e2e surfaces websocket auth rate limiting', () async {
    final server = await _IdentityGatewayServer.start(rateLimitStream: true);
    addTearDown(server.close);

    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        server.baseUrl,
        token: 'nvbx_test_token',
      ),
    );

    await expectLater(
      client.connectStream(),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          'Navivox gateway is temporarily rate limiting authentication attempts',
        ),
      ),
    );
  });

  test('gateway client e2e uses one token source for websocket auth', () async {
    final server = await _IdentityGatewayServer.start();
    addTearDown(server.close);

    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        server.baseUrl,
        token: 'nvbx_test_token',
      ),
    );

    final socket = await client.connectStream();
    await socket.close();

    expect(server.streamProtocols.single, contains(navivoxWebSocketProtocol));
    expect(
      server.streamProtocols.single,
      contains('${navivoxWebSocketTokenProtocolPrefix}bnZieF90ZXN0X3Rva2Vu'),
    );
    expect(server.streamAuthorizationHeaders.single, isNull);
  });

  test(
    'gateway client e2e accepts tls durable reconnect security vocabulary',
    () async {
      final server = await _IdentityGatewayServer.start(
        durableReconnect: {
          'supported': true,
          'issue_endpoint': '/v1/navivox/device-credentials',
          'auth_methods': ['device_key_challenge'],
          'platforms': ['android'],
          'effective_security': 'tls',
          'blocked_reason': '',
        },
      );
      addTearDown(server.close);

      final client = NavivoxGatewayClient(
        config: NavivoxGatewayConfig.fromBaseUrl(
          server.baseUrl,
          token: 'nvbx_test_token',
        ),
      );

      final capabilities = await client.capabilities();

      expect(capabilities.durableReconnect.effectiveSecurity, 'tls');
      expect(
        capabilities.durableReconnect.readinessKind,
        ReconnectReadinessKind.available,
      );
    },
  );

  test(
    'gateway channel e2e trusts authenticated status gateway identity and label',
    () async {
      final server = await _IdentityGatewayServer.start();
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: 'nvbx_test_token');

      expect(server.statusRequests, 1);
      expect(channel.state.activeServer?.name, 'Kitchen Gormes');
      expect(
        channel.state.profileContacts.single.serverLabel,
        'Kitchen Gormes',
      );

      final session = await _waitForSavedSession();
      expect(session?.baseUrl, server.baseUrl);
      expect(session?.gatewayId, 'gw_0123456789abcdef0123456789abcdef');
    },
  );
}

Future<SavedSession?> _waitForSavedSession() async {
  final service = SessionPersistenceService();
  for (var i = 0; i < 20; i += 1) {
    final session = await service.loadSession();
    if (session?.gatewayId != null) return session;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return service.loadSession();
}

class _IdentityGatewayServer {
  _IdentityGatewayServer._(
    this._server,
    this._durableReconnect, {
    required this.maxRequestBytes,
    required this.streamAvailable,
    required this.rateLimitStatus,
    required this.rateLimitStream,
    required this.redirectStatus,
    required this.unsupportedMediaStatus,
  });

  final HttpServer _server;
  final Map<String, Object?> _durableReconnect;
  final int maxRequestBytes;
  final bool streamAvailable;
  final bool rateLimitStatus;
  final bool rateLimitStream;
  final bool redirectStatus;
  final bool unsupportedMediaStatus;
  final streamProtocols = <List<String>>[];
  final streamAuthorizationHeaders = <String?>[];
  final streamMessages = <Map<String, Object?>>[];
  final redirectAuthorizationHeaders = <String?>[];
  var statusRequests = 0;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_IdentityGatewayServer> start({
    Map<String, Object?>? durableReconnect,
    int maxRequestBytes = 1048576,
    bool streamAvailable = false,
    bool rateLimitStatus = false,
    bool rateLimitStream = false,
    bool redirectStatus = false,
    bool unsupportedMediaStatus = false,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _IdentityGatewayServer._(
      server,
      durableReconnect ??
          {
            'supported': false,
            'issue_endpoint': '',
            'auth_methods': <Object?>[],
            'platforms': ['android'],
            'effective_security': 'loopback',
            'blocked_reason':
                'Durable credential issuance is not implemented yet.',
          },
      maxRequestBytes: maxRequestBytes,
      streamAvailable: streamAvailable,
      rateLimitStatus: rateLimitStatus,
      rateLimitStream: rateLimitStream,
      redirectStatus: redirectStatus,
      unsupportedMediaStatus: unsupportedMediaStatus,
    );
    server.listen(fake._handle);
    return fake;
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    if (!_authorized(request)) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }
    if (request.uri.path == '/v1/navivox/status') {
      if (redirectStatus) {
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          '$baseUrl/redirect-target',
        );
        await request.response.close();
        return;
      }
      if (rateLimitStatus) {
        request.response.statusCode = HttpStatus.tooManyRequests;
        await request.response.close();
        return;
      }
      if (unsupportedMediaStatus) {
        request.response.statusCode = HttpStatus.unsupportedMediaType;
        await request.response.close();
        return;
      }
      statusRequests++;
      _writeJson(request.response, {
        'enabled': true,
        'gateway_id': 'gw_0123456789abcdef0123456789abcdef',
        'gateway_label': ' Kitchen Gormes ',
        'protocol_version': 'navivox.v1',
        'websocket_protocols': ['navivox.v1'],
        'capabilities': ['profile_routing'],
        'capabilities_url': '/v1/navivox/capabilities',
        'transport_security': {
          'effective_security': 'loopback',
          'exposure_mode': 'local',
          'tls': false,
          'private_network': false,
          'durable_credentials_allowed': false,
        },
        'sessions': 0,
        'ws_connections': 0,
      });
      return;
    }
    if (request.uri.path == '/redirect-target') {
      redirectAuthorizationHeaders.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      _writeJson(request.response, {
        'enabled': true,
        'gateway_id': 'gw_redirect_followed',
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/capabilities') {
      _writeJson(
        request.response,
        _capabilities(
          _durableReconnect,
          maxRequestBytes: maxRequestBytes,
          streamAvailable: streamAvailable,
        ),
      );
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-routing') {
      _writeJson(request.response, {'profiles': <Object?>[]});
      return;
    }
    if (request.uri.path == '/v1/navivox/stream') {
      if (rateLimitStream) {
        request.response.statusCode = HttpStatus.tooManyRequests;
        await request.response.close();
        return;
      }
      final requestedProtocols =
          request.headers['sec-websocket-protocol']
              ?.expand((value) => value.split(','))
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false) ??
          <String>[];
      streamProtocols.add(requestedProtocols);
      streamAuthorizationHeaders.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      final socket = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: (protocols) =>
            protocols.contains(navivoxWebSocketProtocol)
            ? navivoxWebSocketProtocol
            : null,
      );
      socket.listen((raw) {
        if (raw is! String) return;
        streamMessages.add(Map<String, Object?>.from(jsonDecode(raw) as Map));
      });
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  bool _authorized(HttpRequest request) {
    if (request.headers.value(HttpHeaders.authorizationHeader) ==
        'Bearer nvbx_test_token') {
      return true;
    }
    final protocols = request.headers['sec-websocket-protocol'] ?? const [];
    return protocols
        .expand((value) => value.split(','))
        .map((value) => value.trim())
        .contains('${navivoxWebSocketTokenProtocolPrefix}bnZieF90ZXN0X3Rva2Vu');
  }
}

Map<String, Object?> _capabilities(
  Map<String, Object?> durableReconnect, {
  required int maxRequestBytes,
  required bool streamAvailable,
}) {
  return {
    'object': 'gormes.navivox.capabilities',
    'protocol_version': 'navivox.v1',
    'capabilities': ['profile_routing', if (streamAvailable) 'stream_turns'],
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
        'description': 'Capabilities',
      },
      {
        'method': 'GET',
        'path': '/v1/navivox/profile-routing',
        'auth': 'navivox',
        'stability': 'stable',
        'description': 'Profile routing',
      },
      if (streamAvailable)
        {
          'method': 'WS',
          'path': '/v1/navivox/stream',
          'auth': 'navivox',
          'stability': 'stable',
          'description': 'Stream turns',
        },
    ],
    'profile_management': {
      'contacts_endpoint': '/v1/navivox/profile-contacts',
      'routing_endpoint': '/v1/navivox/profile-routing',
      'create_from_seed_endpoint': '/v1/navivox/profile-seed',
      'dashboard_api_exposed': false,
      'supported_actions': ['routing_read'],
      'unsupported_actions': ['contact_snapshot'],
      'profile_contract_parts': ['profile_routing'],
    },
    'attachments': {
      'max_request_bytes': maxRequestBytes,
      'opaque_upload_ids': false,
      'raw_local_paths_accepted': false,
      'workspace_file_attach': false,
      'mime_allowlist': <Object?>[],
      'retention': 'not_accepted',
    },
    'voice': {
      'device_transcribed_text_turns': true,
      'raw_audio_upload': false,
      'voice_profiles_endpoint': '/v1/navivox/voice-profiles',
      'run_records_endpoint': '',
      'stt_providers': <Object?>[],
      'tts_providers': <Object?>[],
    },
    'streams': {
      'canonical_endpoint': '/v1/navivox/stream',
      'transport': 'websocket',
      'event_kinds': <Object?>[],
      'openai_runs_bridge': false,
    },
    'durable_reconnect': durableReconnect,
  };
}

void _writeJson(HttpResponse response, Object? body) {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  unawaited(response.close());
}
