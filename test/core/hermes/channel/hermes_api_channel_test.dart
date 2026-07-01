import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/channel/hermes_api_channel.dart';
import 'package:navivox/core/hermes/hermes_api.dart';
import 'package:navivox/core/hermes/models/hermes_chat_turn.dart';
import 'package:navivox/core/protocol/voice/models/navivox_voice_run.dart';

void main() {
  test(
    'connect selects the first existing session and loads its messages',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );

      await channel.connect(baseUrl: 'http://127.0.0.1:8642', apiKey: 'key');

      expect(channel.state.status, HermesConnectionStatus.connected);
      expect(channel.state.sessions.single.id, 'sess_1');
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
    },
  );

  test('connect creates a session with a generated id when none exist', () async {
    final posts = <String, Map<String, Object?>>{};
    final channel = HermesApiChannel(
      sessionIdFactory: () => 'navi-test-1',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => '{"object":"list","data":[]}',
            '/api/sessions/navi-test-1/messages' =>
              '{"object":"list","session_id":"navi-test-1","data":[]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = {};
          return '{"object":"hermes.session","session":{"id":"navi-test-1","source":"api_server"}}';
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.status, HermesConnectionStatus.connected);
    expect(channel.state.activeSessionId, 'navi-test-1');
    expect(posts.keys, ['/api/sessions']);
  });

  test('connect surfaces a bounded error without throwing', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => throw StateError('offline'),
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('offline'));
  });

  test(
    'sendText appends the user turn, streams assistant deltas, then reconciles with server history',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) {
            expect(uri.path, '/api/sessions/sess_1/chat/stream');
            return Stream.fromIterable([
              'event: assistant.delta\ndata: {"delta":"Hi"}\n\n',
              'event: assistant.delta\ndata: {"delta":" there"}\n\ndata: [DONE]\n\n',
            ]);
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      var streamingSeen = false;
      channel.addListener(() {
        final last = channel.state.activeMessages.lastOrNull;
        if (last?.status == HermesTurnStatus.streaming) streamingSeen = true;
      });

      await channel.sendText('Hello');

      expect(streamingSeen, isTrue);
      expect(messagesRequests, 2);
      final turns = channel.state.activeMessages;
      expect(turns.map((t) => t.text), ['Hello', 'Hi there']);
      expect(turns.last.author, HermesTurnAuthor.assistant);
      expect(turns.last.status, HermesTurnStatus.completed);
    },
  );

  test(
    'selectSession switches the active session and loads its messages',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_2/messages' =>
                '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"From two"}]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      expect(channel.state.activeSessionId, 'sess_1');

      await channel.selectSession('sess_2');

      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'From two');
    },
  );

  test('createSession creates and selects a new session', () async {
    final posts = <String, Map<String, Object?>>{};
    final channel = HermesApiChannel(
      sessionIdFactory: () => 'navi-test-2',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/navi-test-2/messages' =>
              '{"object":"list","session_id":"navi-test-2","data":[]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return '{"object":"hermes.session","session":{"id":"navi-test-2","source":"api_server","title":"New chat"}}';
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.createSession(title: 'New chat');

    expect(posts['/api/sessions'], {'id': 'navi-test-2', 'title': 'New chat'});
    expect(channel.state.activeSessionId, 'navi-test-2');
    expect(channel.state.sessions.map((s) => s.id), ['sess_1', 'navi-test-2']);
    expect(channel.state.activeMessages, isEmpty);
  });

  test(
    'continuous voice: stage then submit sends the transcript as a Hermes text turn',
    () async {
      final sentMessages = <String>[];
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) {
            sentMessages.add((jsonDecode(body) as Map)['message'] as String);
            return Stream.fromIterable(['data: [DONE]\n\n']);
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final voiceRunId = channel.startVoiceRun();
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.recording,
      );

      channel.stageVoiceRunTranscript(
        voiceRunId: voiceRunId,
        transcript: 'turn the lights on',
        duration: const Duration(seconds: 2),
        confidence: 0.9,
      );
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.pendingSend,
      );

      channel.submitVoiceRun(voiceRunId);
      await pumpEventQueue();

      expect(sentMessages, ['turn the lights on']);
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.completed,
      );
      // Reconciled with server-confirmed history after the streamed turn.
      expect(channel.state.activeMessages.map((t) => t.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test(
    'cancelVoiceRun marks the run cancelled without sending anything',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) =>
              throw StateError('should not send while cancelling'),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final voiceRunId = channel.startVoiceRun();
      channel.cancelVoiceRun(voiceRunId, reason: 'user cancelled');

      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.cancelled,
      );
      expect(channel.state.activeVoiceRun, isNull);
    },
  );

  test(
    'sendText uses run transport when advertised: streams deltas, surfaces an approval, then reconciles',
    () async {
      final approvals = <NavivoxApprovalRequest>[];
      var messagesRequests = 0;
      final posts = <String, Map<String, Object?>>{};
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) {
            expect(uri.path, '/v1/runs/run_1/events');
            return Stream.fromIterable([
              'event: message.delta\ndata: {"delta":"Hi"}\n\n',
              'event: approval.request\ndata: {"approval_id":"appr_1","prompt":"Run rm -rf?","risk":"high"}\n\n',
              'event: run.completed\ndata: {}\n\ndata: [DONE]\n\n',
            ]);
          },
        ),
      );
      channel.approvalRequests.listen(approvals.add);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('rm the temp dir');

      expect(posts['/v1/runs'], {
        'session_id': 'sess_1',
        'message': 'rm the temp dir',
      });
      expect(approvals, hasLength(1));
      expect(approvals.single.id, 'appr_1');
      expect(approvals.single.prompt, 'Run rm -rf?');
      expect(approvals.single.risk, 'high');
      // Reconciled with server-confirmed history after the run completed.
      expect(channel.state.activeMessages.map((t) => t.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test(
    'sendText via run transport tracks tool events by call id instead of duplicating turns',
    () async {
      var messagesRequests = 0;
      final states = <HermesChannelState>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => Stream.fromIterable([
            'event: tool.started\ndata: {"tool":"bash","preview":"ls -la"}\n\n',
            'event: message.delta\ndata: {"delta":"Looking"}\n\n',
            'event: tool.completed\ndata: {"tool":"bash","result_text":"file1"}\n\n',
            'event: message.delta\ndata: {"delta":" done"}\n\ndata: [DONE]\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      channel.addListener(() => states.add(channel.state));

      await channel.sendText('list the files');

      // Snapshot from mid-run, before reconciliation replaces the transcript
      // with server-confirmed history: exactly one tool-call turn (not two),
      // updated in place from `running` to `completed`, ordered before the
      // streaming assistant reply.
      final duringRun = states.lastWhere(
        (s) => s.activeMessages.any((t) => t.kind == HermesTurnKind.toolCall),
      );
      final turns = duringRun.activeMessages;
      expect(
        turns.where((t) => t.kind == HermesTurnKind.toolCall),
        hasLength(1),
      );
      final toolTurn = turns.firstWhere(
        (t) => t.kind == HermesTurnKind.toolCall,
      );
      final toolIndex = turns.indexOf(toolTurn);
      final assistantIndex = turns.indexWhere(
        (t) => t.author == HermesTurnAuthor.assistant,
      );
      expect(toolIndex, lessThan(assistantIndex));
      expect(toolTurn.toolCall?.name, 'bash');
      expect(toolTurn.toolCall?.status, 'completed');
      expect(toolTurn.toolCall?.result, 'file1');
    },
  );

  test('respondToApproval answers the active run', () async {
    final posts = <String, Map<String, Object?>>{};
    // Left open deliberately: the run is still active awaiting the
    // operator's approval decision when respondToApproval is called.
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();
    openRunEvents.add(
      'event: approval.request\ndata: {"approval_id":"appr_1"}\n\n',
    );
    await pumpEventQueue();

    channel.respondToApproval(
      approvalId: 'appr_1',
      decision: HermesApprovalDecision.always,
    );
    await pumpEventQueue();

    expect(posts['/v1/runs/run_1/approval'], {
      'approval_id': 'appr_1',
      'decision': 'always',
    });
  });

  test('stopActiveTurn stops the active run on the server', () async {
    final posts = <String, Map<String, Object?>>{};
    // Left open deliberately: simulates a long-running turn that only stops
    // because the operator calls stopActiveTurn, not because the stream ends.
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('keep going forever'));
    await pumpEventQueue();

    channel.stopActiveTurn();
    await pumpEventQueue();

    expect(posts['/v1/runs/run_1/stop'], <String, Object?>{});
  });
}

const _capabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {},
  "endpoints": {}
}
''';

const _runsCapableCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "session_chat_streaming": true,
    "run_submission": true,
    "run_status": true,
    "run_events_sse": true,
    "run_stop": true,
    "run_approval_response": true,
    "tool_progress_events": true
  },
  "endpoints": {
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
    {"id": "sess_1", "source": "api_server", "title": "Demo", "message_count": 1}
  ]
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

const _twoSessionsFixture = '''
{
  "object": "list",
  "data": [
    {"id": "sess_1", "source": "api_server", "title": "One", "message_count": 1},
    {"id": "sess_2", "source": "api_server", "title": "Two", "message_count": 1}
  ]
}
''';

const _reconciledMessagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"},
    {"id": "msg_2", "session_id": "sess_1", "role": "assistant", "content": "Hi there"}
  ]
}
''';
