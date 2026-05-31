import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway_navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

import '../support/gateway_routing_test_support.dart';

void main() {
  test('connects to gateway and streams a chat turn', () async {
    final server = await _FakeGatewayServer.start();
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

    expect(channel.state.activeServer?.name, 'Gormes Gateway');
    expect(channel.state.activeServer?.status, contains('Gateway online'));

    final completed = Completer<void>();
    channel.addListener(() {
      final texts = channel.state.messagesList.map((m) => m.text).toList();
      if (texts.contains('hello from gateway') && !completed.isCompleted) {
        completed.complete();
      }
    });

    channel.sendText('hello gateway');

    final sent = await server.nextClientMessage;
    expect(sent['type'], 'start_turn');
    expect(sent['text'], 'hello gateway');
    await completed.future.timeout(const Duration(seconds: 2));

    final messages = channel.state.messagesList;
    expect(messages.where((m) => m.text == 'hello gateway'), hasLength(1));
    final assistant = messages.singleWhere(
      (m) => m.text == 'hello from gateway',
    );
    expect(assistant.runRecordReference, 'run-${sent['request_id']}');
    expect(channel.state.runRecordInspectionAvailable, isTrue);
  });

  test(
    'keeps diagnostics visible and gates feature endpoints when capabilities fail',
    () async {
      final server = await _FakeGatewayServer.start(
        capabilitiesUnavailable: true,
      );
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

      expect(server.profileContactsRequests, 0);
      expect(server.streamRequests, 0);
      expect(
        channel.state.activeServer?.status,
        contains('Capabilities unavailable'),
      );
      expect(
        channel.state.profileContacts.single.health,
        NavivoxProfileHealth.warning,
      );
      expect(channel.state.profileContacts.single.micAvailable, isFalse);

      channel.sendText('hello closed gate');

      expect(channel.state.messagesList.last.text, 'Gateway is not connected.');
    },
  );

  test('run records are unavailable when not advertised', () async {
    final server = await _FakeGatewayServer.start(runRecordsAvailable: false);
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

    expect(channel.state.runRecordInspectionAvailable, isFalse);
    await expectLater(channel.runRecord('run-1'), throwsA(isA<StateError>()));
  });

  test('selected profile scope is included in gateway turn metadata', () async {
    final server = await _FakeGatewayServer.start();
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);
    channel.selectProfileContact(
      serverId: 'navivox-gateway',
      profileId: 'default',
    );

    channel.sendText('hello scoped gateway');

    final sent = await server.nextClientMessage;
    final metadata = Map<String, Object?>.from(sent['metadata'] as Map);
    expect(metadata['server_id'], 'navivox-gateway');
    expect(metadata['profile_id'], 'default');
    expect(metadata['client'], 'navivox');
  });

  test(
    'loads profile contacts from snapshot and applies gateway updates',
    () async {
      final server = await _FakeGatewayServer.start(
        contacts: [
          {
            'server_id': 'local-gormes',
            'profile_id': 'mineru',
            'display_name': 'Mineru Builder',
            'server_label': 'local',
            'avatar_seed': 'local-gormes:mineru',
            'latest_preview': 'Ready to work',
            'latest_preview_kind': 'status',
            'latest_preview_at': '2026-05-18T06:30:00Z',
            'health': 'online',
            'workspace_root_count': 2,
            'workspace_roots_ok': true,
            'workspace_roots_warning': 0,
            'workspace_roots_error': 0,
            'attention_badges': ['approval'],
            'mic_available': true,
            'voice_capability': {
              'device_stt': 'available',
              'server_stt': 'planned',
              'server_tts': 'planned',
              'disabled_reason': '',
              'recovery_action': '',
            },
            'active_turn_state': 'idle',
          },
        ],
        streamEvents: (requestId) => [
          {
            'type': 'profile_contact_update',
            'request_id': requestId,
            'contact': {
              'server_id': 'local-gormes',
              'profile_id': 'mineru',
              'display_name': 'Mineru Builder',
              'server_label': 'local',
              'avatar_seed': 'local-gormes:mineru',
              'latest_preview': 'Checking status',
              'latest_preview_kind': 'user',
              'latest_preview_at': '2026-05-18T06:31:00Z',
              'health': 'warning',
              'workspace_root_count': 2,
              'workspace_roots_ok': false,
              'workspace_roots_warning': 1,
              'workspace_roots_error': 0,
              'attention_badges': ['workspace'],
              'mic_available': false,
              'active_turn_state': 'active',
            },
          },
        ],
      );
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

      expect(channel.state.profileContacts, hasLength(1));
      expect(channel.state.profileContacts.single.profileId, 'mineru');
      expect(
        channel.state.profileContacts.single.latestPreview,
        'Ready to work',
      );
      expect(channel.state.profileContacts.single.workspaceRootCount, 2);
      expect(channel.state.profileContacts.single.attentionBadges, [
        'approval',
      ]);
      final initialContact = channel.state.profileContacts.single;
      expect(initialContact.voiceCapability.deviceStt, 'available');
      expect(initialContact.voiceCapability.serverStt, 'planned');
      expect(initialContact.voiceCapability.serverTts, 'planned');
      expect(initialContact.voiceCapability.enabled, isTrue);

      final updated = Completer<void>();
      channel.addListener(() {
        final contacts = channel.state.profileContacts;
        if (contacts.length == 1 &&
            contacts.single.latestPreview == 'Checking status' &&
            !updated.isCompleted) {
          updated.complete();
        }
      });

      channel.selectProfileContact(
        serverId: 'local-gormes',
        profileId: 'mineru',
      );
      channel.sendText('Checking status');
      await server.nextClientMessage;
      await updated.future.timeout(const Duration(seconds: 2));

      final contact = channel.state.profileContacts.single;
      expect(contact.health, NavivoxProfileHealth.warning);
      expect(contact.workspaceRootsOk, isFalse);
      expect(contact.workspaceRootsWarning, 1);
      expect(contact.micAvailable, isFalse);
      expect(contact.activeTurnState, 'active');
    },
  );

  test('requestAgentList refreshes Gormes profile contacts', () async {
    var contacts = <Map<String, Object?>>[
      {
        'server_id': 'local-gormes',
        'profile_id': 'mineru',
        'display_name': 'Mineru Builder',
        'server_label': 'local',
        'health': 'online',
        'latest_preview': 'Initial profile snapshot',
        'workspace_root_count': 1,
        'workspace_roots_ok': true,
        'attention_badges': <String>[],
        'mic_available': true,
        'active_turn_state': 'idle',
      },
    ];
    final server = await _FakeGatewayServer.start(
      contactsProvider: () => contacts,
    );
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

    expect(
      channel.state.profileContacts.single.latestPreview,
      'Initial profile snapshot',
    );

    contacts = [
      {
        'server_id': 'local-gormes',
        'profile_id': 'mineru',
        'display_name': 'Mineru Builder',
        'server_label': 'local',
        'health': 'warning',
        'latest_preview': 'Refreshed profile snapshot',
        'workspace_root_count': 2,
        'workspace_roots_ok': false,
        'workspace_roots_warning': 1,
        'workspace_roots_error': 0,
        'attention_badges': ['workspace'],
        'mic_available': false,
        'active_turn_state': 'idle',
      },
    ];

    final refreshed = Completer<void>();
    channel.addListener(() {
      final stateContacts = channel.state.profileContacts;
      if (stateContacts.length == 1 &&
          stateContacts.single.latestPreview == 'Refreshed profile snapshot' &&
          !refreshed.isCompleted) {
        refreshed.complete();
      }
    });

    channel.requestAgentList();
    await refreshed.future.timeout(const Duration(seconds: 2));

    final contact = channel.state.profileContacts.single;
    expect(contact.latestPreview, 'Refreshed profile snapshot');
    expect(contact.health, NavivoxProfileHealth.warning);
    expect(contact.workspaceRootCount, 2);
    expect(contact.workspaceRootsOk, isFalse);
  });

  test(
    'requestAgentList does not repeat unavailable refresh guidance',
    () async {
      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      channel.requestAgentList();
      channel.requestAgentList();
      await Future<void>.delayed(Duration.zero);

      final refreshMessages = channel.state.messagesList
          .where(
            (message) =>
                message.author == NavivoxMessageAuthor.system &&
                message.text == 'Connect to Gormes to refresh profiles.',
          )
          .toList();

      expect(refreshMessages, hasLength(1));
    },
  );

  test(
    'voice transcript renders locally and submits as a gateway turn',
    () async {
      final server = await _FakeGatewayServer.start();
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

      channel.sendVoice(transcript: 'hello by voice');

      final sent = await server.nextClientMessage;
      expect(sent['type'], 'start_turn');
      expect(sent['text'], 'hello by voice');

      final voiceMessages = channel.state.messagesList
          .where((message) => message.kind == NavivoxMessageKind.voice)
          .toList();
      expect(voiceMessages, hasLength(1));
      expect(voiceMessages.single.author, NavivoxMessageAuthor.user);
      expect(voiceMessages.single.text, 'hello by voice');
    },
  );

  test(
    'voice run submits transcript through existing start_turn path',
    () async {
      final server = await _FakeGatewayServer.start();
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

      final voiceRunId = channel.startVoiceRun();
      channel.stageVoiceRunTranscript(
        voiceRunId: voiceRunId,
        transcript: 'hello by voice',
        duration: const Duration(milliseconds: 800),
        confidence: 0.88,
      );
      channel.submitVoiceRun(voiceRunId);

      final sent = await server.nextClientMessage;
      expect(sent['type'], 'start_turn');
      expect(sent['text'], 'hello by voice');

      final run = channel.state.voiceRuns[voiceRunId];
      expect(run?.status, NavivoxVoiceRunStatus.submitted);
      expect(run?.requestId, isNotEmpty);

      final voiceMessages = channel.state.messagesList
          .where((message) => message.kind == NavivoxMessageKind.voice)
          .toList();
      expect(voiceMessages, hasLength(1));
      expect(voiceMessages.single.voice?.voiceRunId, voiceRunId);
    },
  );

  test('cancelled voice run does not send a gateway turn', () async {
    final server = await _FakeGatewayServer.start();
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

    final voiceRunId = channel.startVoiceRun();
    channel.stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: 'do not send',
      duration: const Duration(milliseconds: 800),
      confidence: 0.88,
    );
    channel.cancelVoiceRun(voiceRunId);

    expect(
      channel.state.voiceRuns[voiceRunId]?.status,
      NavivoxVoiceRunStatus.cancelled,
    );
    expect(
      channel.state.messagesList.where(
        (m) => m.kind == NavivoxMessageKind.voice,
      ),
      isEmpty,
    );
  });

  test('safety events render as typed safety and approval messages', () async {
    final server = await _FakeGatewayServer.start(
      streamEvents: (requestId) => [
        {
          'type': 'session_started',
          'request_id': requestId,
          'session_id': 's-safe',
        },
        {
          'type': 'safety_warning',
          'request_id': requestId,
          'session_id': 's-safe',
          'safety_id': 'safe-1',
          'severity': 'high',
          'message': 'Shell command wants to modify files',
          'risk': 'Writes may change the workspace',
        },
        {
          'type': 'approval_required',
          'request_id': requestId,
          'session_id': 's-safe',
          'approval_id': 'approval-1',
          'tool_call_id': 'call-shell',
          'message': 'Approve shell.run?',
          'risk': 'Command can edit files',
        },
      ],
    );
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

    final approvalCompleter = Completer<NavivoxApprovalRequest>();
    final approvalSub = channel.approvalRequests.listen((request) {
      if (!approvalCompleter.isCompleted) approvalCompleter.complete(request);
    });
    addTearDown(approvalSub.cancel);

    final completed = Completer<void>();
    channel.addListener(() {
      final kinds = channel.state.messagesList.map((message) => message.kind);
      if (kinds.contains(NavivoxMessageKind.safetyWarning) &&
          kinds.contains(NavivoxMessageKind.approvalRequest) &&
          !completed.isCompleted) {
        completed.complete();
      }
    });

    channel.sendText('run shell command');
    await server.nextClientMessage;
    await completed.future.timeout(const Duration(seconds: 2));

    final messages = channel.state.messagesList;
    expect(
      messages.where((m) => m.text == 'Shell command wants to modify files'),
      isEmpty,
      reason: 'safety warnings must not masquerade as normal text messages',
    );
    final warning = messages.singleWhere(
      (message) => message.kind == NavivoxMessageKind.safetyWarning,
    );
    expect(warning.safetyNotice?.severity, 'high');
    expect(warning.safetyNotice?.risk, 'Writes may change the workspace');

    final approval = messages.singleWhere(
      (message) => message.kind == NavivoxMessageKind.approvalRequest,
    );
    expect(approval.safetyNotice?.approvalId, 'approval-1');
    expect(approval.safetyNotice?.toolCallId, 'call-shell');

    final approvalRequest = await approvalCompleter.future.timeout(
      const Duration(seconds: 2),
    );
    expect(approvalRequest.id, 'approval-1');
    expect(approvalRequest.toolCallId, 'call-shell');
    expect(approvalRequest.prompt, 'Approve shell.run?');
    expect(approvalRequest.risk, 'Command can edit files');
  });

  test('tool progress events render as one durable tool-call card', () async {
    final server = await _FakeGatewayServer.start(
      streamEvents: (requestId) => [
        {
          'type': 'session_started',
          'request_id': requestId,
          'session_id': 's-test',
        },
        {
          'type': 'tool_call_started',
          'request_id': requestId,
          'session_id': 's-test',
          'tool_call_id': 'req-tool-browser-1',
          'tool_name': 'browser_navigate',
          'status': 'started',
          'message': 'browser_navigate started',
        },
        {
          'type': 'tool_call_updated',
          'request_id': requestId,
          'session_id': 's-test',
          'tool_call_id': 'req-tool-browser-1',
          'tool_name': 'browser_navigate',
          'status': 'updated',
          'message': 'browser_navigate opened dashboard with an artifact',
          'metadata': {
            'artifact_id': 'browser-state',
            'artifact_kind': 'page',
            'artifact_title': 'Browser state',
            'artifact_summary': 'Dashboard title and safe URL',
            'artifact_ref': 'artifact://browser-state',
            'secret_token': 'must-not-render',
          },
        },
        {
          'type': 'approval_required',
          'request_id': requestId,
          'session_id': 's-test',
          'approval_id': 'approval-browser',
          'tool_call_id': 'req-tool-browser-1',
          'message': 'Approve browser interaction?',
          'risk': 'Navigates the active browser session',
        },
        {
          'type': 'tool_call_finished',
          'request_id': requestId,
          'session_id': 's-test',
          'tool_call_id': 'req-tool-browser-1',
          'tool_name': 'browser_navigate',
          'status': 'finished',
          'message': 'browser_navigate finished',
          'metadata': {
            'artifacts': [
              {
                'id': 'browser-state',
                'kind': 'page',
                'title': 'Browser state',
                'summary': 'Dashboard title and safe URL',
                'ref': 'artifact://browser-state',
              },
            ],
          },
        },
        {'type': 'done', 'request_id': requestId, 'session_id': 's-test'},
      ],
    );
    addTearDown(server.close);

    final channel = GatewayNavivoxChannel();
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

    final completed = Completer<void>();
    channel.addListener(() {
      final cards = channel.state.messagesList
          .where((message) => message.kind == NavivoxMessageKind.toolCall)
          .toList();
      if (cards.length == 1 &&
          cards.single.toolCall?.status == 'finished' &&
          cards.single.toolCall?.artifacts.length == 1 &&
          !completed.isCompleted) {
        completed.complete();
      }
    });

    channel.sendText('open dashboard');
    await server.nextClientMessage;
    await completed.future.timeout(const Duration(seconds: 2));

    final cards = channel.state.messagesList
        .where((message) => message.kind == NavivoxMessageKind.toolCall)
        .toList();
    expect(cards, hasLength(1));
    final tool = cards.single.toolCall!;
    expect(tool.name, 'browser_navigate');
    expect(tool.status, 'finished');
    expect(tool.summary, 'browser_navigate finished');
    expect(tool.approval?.id, 'approval-browser');
    expect(tool.approval?.status, 'approval_required');
    expect(tool.approval?.prompt, 'Approve browser interaction?');
    expect(tool.approval?.risk, 'Navigates the active browser session');
    expect(tool.artifacts, hasLength(1));
    expect(tool.artifacts.single.id, 'browser-state');
    expect(tool.artifacts.single.kind, 'page');
    expect(tool.artifacts.single.title, 'Browser state');
    expect(tool.artifacts.single.summary, 'Dashboard title and safe URL');
    expect(tool.artifacts.single.ref, 'artifact://browser-state');
    expect(
      channel.state.messagesList
          .where((message) => message.author == NavivoxMessageAuthor.assistant)
          .map((message) => message.text ?? message.toolCall?.summary ?? '')
          .join('\n'),
      isNot(contains('must-not-render')),
    );
  });

  test(
    'malformed tool metadata is bounded and redacted inside the card',
    () async {
      final longMetadata = 'x' * 600;
      final server = await _FakeGatewayServer.start(
        streamEvents: (requestId) => [
          {
            'type': 'session_started',
            'request_id': requestId,
            'session_id': 's-test',
          },
          {
            'type': 'tool_call_updated',
            'request_id': requestId,
            'session_id': 's-test',
            'tool_call_id': 'call-malformed',
            'tool_name': 'shell.run',
            'status': 'updated',
            'message': longMetadata,
            'metadata': {
              'secret_token': 'raw-secret-value',
              'stdout': longMetadata,
              'bad_artifact': {'raw_secret': 'raw-secret-value'},
            },
          },
          {'type': 'done', 'request_id': requestId, 'session_id': 's-test'},
        ],
      );
      addTearDown(server.close);

      final channel = GatewayNavivoxChannel();
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: server.baseUrl, token: gatewayTestToken);

      final completed = Completer<void>();
      channel.addListener(() {
        final card = channel.state.messagesList
            .where((message) => message.kind == NavivoxMessageKind.toolCall)
            .firstOrNull;
        if (card?.toolCall?.artifacts.isNotEmpty == true &&
            !completed.isCompleted) {
          completed.complete();
        }
      });

      channel.sendText('run malformed tool');
      await server.nextClientMessage;
      await completed.future.timeout(const Duration(seconds: 2));

      final tool = channel.state.messagesList
          .singleWhere((message) => message.kind == NavivoxMessageKind.toolCall)
          .toolCall!;
      expect(tool.summary.length, lessThanOrEqualTo(240));
      expect(tool.artifacts.single.kind, 'metadata');
      expect(tool.artifacts.single.title, 'Tool metadata');
      expect(
        tool.artifacts.single.summary,
        isNot(contains('raw-secret-value')),
      );
      expect(tool.artifacts.single.summary!.length, lessThanOrEqualTo(240));
      expect(
        channel.state.messagesList
            .where((message) => message.kind == NavivoxMessageKind.text)
            .map((message) => message.text)
            .join('\n'),
        isNot(contains('raw-secret-value')),
      );
    },
  );
}

class _FakeGatewayServer {
  _FakeGatewayServer._(
    this._server,
    this.port,
    this._streamEvents,
    this._contacts,
    this._contactsProvider,
    this._capabilities,
    this._capabilitiesUnavailable,
    this._runRecordsAvailable,
  );

  final HttpServer _server;
  final int port;
  final List<Map<String, Object?>> Function(String requestId)? _streamEvents;
  final List<Map<String, Object?>>? _contacts;
  final List<Map<String, Object?>> Function()? _contactsProvider;
  final Map<String, Object?>? _capabilities;
  final bool _capabilitiesUnavailable;
  final bool _runRecordsAvailable;
  final Completer<Map<String, Object?>> _nextClientMessage = Completer();
  var profileContactsRequests = 0;
  var streamRequests = 0;

  String get baseUrl => 'http://127.0.0.1:$port';
  Future<Map<String, Object?>> get nextClientMessage =>
      _nextClientMessage.future;

  static Future<_FakeGatewayServer> start({
    List<Map<String, Object?>> Function(String requestId)? streamEvents,
    List<Map<String, Object?>>? contacts,
    List<Map<String, Object?>> Function()? contactsProvider,
    Map<String, Object?>? capabilities,
    bool capabilitiesUnavailable = false,
    bool runRecordsAvailable = true,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _FakeGatewayServer._(
      server,
      server.port,
      streamEvents,
      contacts,
      contactsProvider,
      capabilities,
      capabilitiesUnavailable,
      runRecordsAvailable,
    );
    server.listen(fake._handle);
    return fake;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.uri.path == '/healthz') {
      writeGatewayJson(request.response, {'status': 'ok'});
      return;
    }
    if (!_authorized(request)) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }
    if (request.uri.path == '/v1/navivox/status') {
      writeGatewayJson(request.response, {
        'enabled': true,
        'gateway_id': 'gw_test_gateway',
      });
      return;
    }
    if (request.uri.path == '/v1/navivox/capabilities') {
      if (_capabilitiesUnavailable) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      writeGatewayJson(
        request.response,
        _capabilities ?? _capabilityDocument(),
      );
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-contacts') {
      profileContactsRequests++;
      writeGatewayJson(request.response, {'contacts': _profileContacts()});
      return;
    }
    if (request.uri.path == '/v1/navivox/profile-routing') {
      writeGatewayJson(request.response, {'profiles': <Object?>[]});
      return;
    }
    if (request.uri.path == '/v1/navivox/stream') {
      streamRequests++;
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((raw) {
        final decoded = Map<String, Object?>.from(jsonDecode(raw as String));
        if (!_nextClientMessage.isCompleted) {
          _nextClientMessage.complete(decoded);
        }
        final requestId = decoded['request_id']?.toString() ?? 'req-test';
        for (final event in _eventsFor(requestId)) {
          socket.add(jsonEncode(event));
        }
      });
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Map<String, Object?> _capabilityDocument() {
    final document = gatewayRoutingCapabilityDocument();
    document['capabilities'] = [
      'profile_contacts',
      'profile_routing',
      'stream_turns',
      'turn_control',
    ];
    document['endpoints'] = [
      {
        'method': 'GET',
        'path': '/v1/navivox/status',
        'auth': 'navivox',
        'stability': 'stable',
        'description': 'Runtime status',
      },
      ...List<Map<String, Object?>>.from(document['endpoints'] as List),
    ];
    document['voice'] = {
      ...Map<String, Object?>.from(document['voice'] as Map),
      'run_records_endpoint': _runRecordsAvailable
          ? '/v1/navivox/run-records/{run_id_or_session_id}'
          : '',
    };
    document['streams'] = {
      ...Map<String, Object?>.from(document['streams'] as Map),
      'event_kinds': [
        'session_started',
        'assistant_delta',
        'assistant_message',
        'done',
      ],
    };
    return document;
  }

  List<Map<String, Object?>> _profileContacts() {
    return _contactsProvider?.call() ??
        _contacts ??
        [
          {
            'server_id': 'navivox-gateway',
            'profile_id': 'default',
            'display_name': 'Default profile',
            'server_label': 'Gormes Gateway',
            'health': 'online',
            'latest_preview': 'Gateway online',
            'latest_preview_kind': 'status',
            'workspace_root_count': 1,
            'workspace_roots_ok': true,
            'workspace_roots_warning': 0,
            'workspace_roots_error': 0,
            'attention_badges': <String>[],
            'mic_available': true,
            'active_turn_state': 'idle',
          },
        ];
  }

  bool _authorized(HttpRequest request) {
    return isAuthorizedGatewayRequest(request);
  }

  List<Map<String, Object?>> _eventsFor(String requestId) {
    final custom = _streamEvents;
    if (custom != null) {
      return custom(requestId);
    }
    return [
      {
        'type': 'session_started',
        'request_id': requestId,
        'session_id': 's-test',
      },
      {
        'type': 'assistant_delta',
        'request_id': requestId,
        'session_id': 's-test',
        'text': 'hello ',
      },
      {
        'type': 'assistant_message',
        'request_id': requestId,
        'session_id': 's-test',
        'text': 'hello from gateway',
        'run_record_ref': 'run-$requestId',
      },
      {'type': 'done', 'request_id': requestId, 'session_id': 's-test'},
    ];
  }
}
