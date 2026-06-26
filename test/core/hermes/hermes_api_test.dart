import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/hermes_api.dart';

void main() {
  test(
    'constructs Hermes API URLs without stale credentials or query state',
    () {
      final config = HermesApiConfig.fromBaseUrl(
        'https://user:old-key@hermes.example:8642/setup?api_key=old#frag',
        apiKey: ' hermes_live_key ',
      );

      expect(config.healthUri.toString(), 'https://hermes.example:8642/health');
      expect(
        config.capabilitiesUri.toString(),
        'https://hermes.example:8642/v1/capabilities',
      );
      expect(
        config.sessionsUri.toString(),
        'https://hermes.example:8642/api/sessions',
      );
      expect(
        config.sessionUri(' s/1 ').toString(),
        'https://hermes.example:8642/api/sessions/s%2F1',
      );
      expect(
        config.sessionMessagesUri('s 1').toString(),
        'https://hermes.example:8642/api/sessions/s%201/messages',
      );
      expect(
        config.sessionChatStreamUri('s 1').toString(),
        'https://hermes.example:8642/api/sessions/s%201/chat/stream',
      );
      expect(
        config.runEventsUri('run/1').toString(),
        'https://hermes.example:8642/v1/runs/run%2F1/events',
      );
      expect(
        config.runApprovalUri('run 1').toString(),
        'https://hermes.example:8642/v1/runs/run%201/approval',
      );
      expect(
        config.runStopUri('run 1').toString(),
        'https://hermes.example:8642/v1/runs/run%201/stop',
      );
      expect(config.headers, {'Authorization': 'Bearer hermes_live_key'});
    },
  );

  test('rejects blank Hermes path identifiers before ambiguous calls', () {
    final config = HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642');

    expect(() => config.sessionUri('  '), throwsArgumentError);
    expect(() => config.runEventsUri('\t'), throwsArgumentError);
  });

  test(
    'parses capability document and gates chat and run transports',
    () async {
      final capabilities = HermesCapabilityDocument.fromJson(
        jsonDecode(_capabilitiesFixture) as Map<String, Object?>,
      );
      final policy = HermesTransportPolicy(capabilities);

      expect(capabilities.auth.required, isTrue);
      expect(capabilities.supportsFeature('session_chat_streaming'), isTrue);
      expect(policy.supportsSessionChatStream, isTrue);
      expect(policy.supportsRunsTransport, isTrue);
      expect(policy.supportsConfigWrite, isFalse);
      expect(policy.supportsRealtimeVoice, isFalse);
    },
  );

  test(
    'client parses health, sessions, created sessions, and messages',
    () async {
      final requests = <String>[];
      final posts = <String, Map<String, Object?>>{};
      final client = HermesApiClient(
        config: HermesApiConfig.fromBaseUrl(
          'http://127.0.0.1:8642',
          apiKey: 'api-key',
        ),
        get: (uri, headers) async {
          expect(headers, {'Authorization': 'Bearer api-key'});
          requests.add(uri.path);
          return switch (uri.path) {
            '/health' => '{"status":"ok","platform":"hermes-agent"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(headers['Authorization'], 'Bearer api-key');
          expect(headers['Content-Type'], 'application/json');
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return '{"object":"hermes.session","session":{"id":"navi-1","source":"api_server","title":"Mobile"}}';
        },
      );

      expect((await client.health()).status, 'ok');
      expect((await client.capabilities()).model, 'hermes-agent');
      expect((await client.listSessions()).single.id, 'sess_1');
      expect((await client.sessionMessages('sess_1')).single.content, 'Hello');

      final created = await client.createSession(id: 'navi-1', title: 'Mobile');
      expect(created.id, 'navi-1');
      expect(posts['/api/sessions'], {'id': 'navi-1', 'title': 'Mobile'});
      expect(requests, [
        '/health',
        '/v1/capabilities',
        '/api/sessions',
        '/api/sessions/sess_1/messages',
      ]);
    },
  );

  test('decodes server-sent events across chunks and keeps multiline data', () {
    final decoder = HermesSseEventDecoder();

    final events = decoder.decode([
      ': keepalive\n',
      'id: 7\nevent: assistant.delta\ndata: first\n',
      'data: second\n\n',
      'event: done\ndata: {}\n\n',
    ]);

    expect(events, hasLength(2));
    expect(events.first.id, '7');
    expect(events.first.event, 'assistant.delta');
    expect(events.first.data, 'first\nsecond');
    expect(events.last.isDone, isTrue);
  });

  test('decodes Hermes JSON SSE payloads and skips malformed events', () {
    final decoder = HermesSseEventDecoder();

    final events = decoder.decodeJsonEvents([
      'event: run.started\ndata: {"run_id":"run_1","session_id":"sess_1"}\n\n',
      'event: assistant.delta\ndata: {not json}\n\n',
      'event: assistant.delta\ndata: {"message_id":"msg_1","delta":"Hi"}\n\n',
      'data: [DONE]\n\n',
    ]);

    expect(events.map((event) => event.name), [
      'run.started',
      'assistant.delta',
      'done',
    ]);
    expect(events.first.runId, 'run_1');
    expect(events[1].delta, 'Hi');
    expect(events.last.isDone, isTrue);
  });
}

const _capabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "session_chat_streaming": true,
    "session_resources": true,
    "run_submission": true,
    "run_status": true,
    "run_events_sse": true,
    "run_stop": true,
    "run_approval_response": true,
    "tool_progress_events": true,
    "admin_config_rw": false,
    "memory_write_api": false,
    "audio_api": false,
    "realtime_voice": false
  },
  "endpoints": {
    "sessions": {"method": "GET", "path": "/api/sessions"},
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_messages": {"method": "GET", "path": "/api/sessions/{session_id}/messages"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"},
    "runs": {"method": "POST", "path": "/v1/runs"},
    "run_status": {"method": "GET", "path": "/v1/runs/{run_id}"},
    "run_events": {"method": "GET", "path": "/v1/runs/{run_id}/events"},
    "run_approval": {"method": "POST", "path": "/v1/runs/{run_id}/approval"},
    "run_stop": {"method": "POST", "path": "/v1/runs/{run_id}/stop"}
  }
}
''';

const _sessionsFixture = '''
{
  "object": "list",
  "data": [
    {
      "id": "sess_1",
      "source": "api_server",
      "model": "hermes-agent",
      "title": "Demo",
      "message_count": 2,
      "last_active": "2026-06-25T12:00:00Z",
      "preview": "Hello"
    }
  ],
  "limit": 50,
  "offset": 0,
  "has_more": false
}
''';

const _messagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"}
  ]
}
''';
