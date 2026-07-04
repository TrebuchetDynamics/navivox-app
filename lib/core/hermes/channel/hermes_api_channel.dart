import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../protocol/navivox_json.dart';
import '../../protocol/voice/models/navivox_voice_run.dart';
import '../client/hermes_api_client.dart';
import '../client/hermes_api_config.dart';
import '../models/hermes_chat_turn.dart';
import '../models/hermes_health.dart';
import '../models/hermes_job.dart';
import '../policy/hermes_transport_policy.dart';
import '../sse/hermes_sse_event_decoder.dart';
import 'hermes_channel.dart';

/// [HermesChannel] backed by [HermesApiClient] against a live Hermes Agent
/// API server. See docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md.
class HermesApiChannel extends ChangeNotifier implements HermesChannel {
  HermesApiChannel({
    HermesApiClient Function(HermesApiConfig config)? clientBuilder,
    String Function()? sessionIdFactory,
    Uuid? uuid,
  }) : _clientBuilder =
           clientBuilder ?? ((config) => HermesApiClient(config: config)),
       _uuid = uuid ?? const Uuid(),
       _sessionIdFactory =
           sessionIdFactory ??
           (() =>
               'navi-${DateTime.now().microsecondsSinceEpoch}-${(uuid ?? const Uuid()).v4()}');

  final HermesApiClient Function(HermesApiConfig) _clientBuilder;
  final String Function() _sessionIdFactory;
  final Uuid _uuid;

  HermesApiClient? _client;
  HermesChannelState _state = const HermesChannelState();
  StreamSubscription<HermesStreamEvent>? _activeStream;
  String? _activeRunId;
  final _approvalController =
      StreamController<NavivoxApprovalRequest>.broadcast();
  final _deletingSessionIds = <String>{};

  @override
  HermesChannelState get state => _state;

  @override
  Stream<NavivoxApprovalRequest> get approvalRequests =>
      _approvalController.stream;

  @override
  void dispose() {
    _approvalController.close();
    super.dispose();
  }

  void _setState(HermesChannelState next) {
    _state = next;
    notifyListeners();
  }

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    _setState(
      _state.copyWith(
        status: HermesConnectionStatus.connecting,
        clearErrorMessage: true,
      ),
    );
    final client = _clientBuilder(
      HermesApiConfig.fromBaseUrl(baseUrl, apiKey: apiKey),
    );
    _client = client;
    try {
      await client.health();
      final capabilities = await client.capabilities();
      final detailedHealth = await _optionalHealth(
        capabilities.advertisesEndpoint(
          'health_detailed',
          'GET',
          '/health/detailed',
        ),
        client.healthDetailed,
      );
      final models = await _optionalCatalogList(
        capabilities.advertisesEndpoint('models', 'GET', '/v1/models'),
        client.listModels,
      );
      final skills = await _optionalCatalogList(
        capabilities.advertisesEndpoint('skills', 'GET', '/v1/skills'),
        client.listSkills,
      );
      final enabledToolsets = await _optionalCatalogList(
        capabilities.advertisesEndpoint('toolsets', 'GET', '/v1/toolsets'),
        client.listEnabledToolsets,
      );
      final jobs = await _optionalJobs(
        capabilities.advertisesEndpoint('jobs', 'GET', '/api/jobs'),
        client.listJobs,
      );
      var sessions = await client.listSessions();
      String activeId;
      if (sessions.isEmpty) {
        final created = await client.createSession(id: _sessionIdFactory());
        sessions = [created];
        activeId = created.id;
      } else {
        activeId = sessions.first.id;
      }
      final messages = await _fetchTurns(client, activeId);
      _setState(
        _state.copyWith(
          status: HermesConnectionStatus.connected,
          capabilities: capabilities,
          detailedHealth: detailedHealth,
          models: models,
          skills: skills,
          enabledToolsets: enabledToolsets,
          jobs: jobs,
          sessions: sessions,
          activeSessionId: activeId,
          messages: {...(_state.messages), activeId: messages},
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          status: HermesConnectionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<HermesHealthStatus?> _optionalHealth(
    bool advertised,
    Future<HermesHealthStatus> Function() load,
  ) async {
    if (!advertised) return null;
    try {
      return await load();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _optionalCatalogList(
    bool advertised,
    Future<List<String>> Function() load,
  ) async {
    if (!advertised) return const [];
    try {
      return await load();
    } catch (_) {
      return const [];
    }
  }

  Future<List<HermesJob>> _optionalJobs(
    bool advertised,
    Future<List<HermesJob>> Function() load,
  ) async {
    if (!advertised) return const [];
    try {
      return await load();
    } catch (_) {
      return const [];
    }
  }

  Future<List<HermesChatTurn>> _fetchTurns(
    HermesApiClient client,
    String sessionId,
  ) async {
    final history = await client.sessionMessages(sessionId);
    return [
      for (final message in history)
        HermesChatTurn(
          id: message.id,
          sessionId: sessionId,
          author: switch (message.role) {
            'user' => HermesTurnAuthor.user,
            'assistant' => HermesTurnAuthor.assistant,
            _ => HermesTurnAuthor.system,
          },
          createdAt: DateTime.now(),
          text: message.content,
        ),
    ];
  }

  @override
  Future<void> disconnect() async {
    _client = null;
    _setState(const HermesChannelState());
  }

  @override
  Future<void> selectSession(String sessionId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    _setState(_state.copyWith(activeSessionId: sessionId));
    _setTurns(sessionId, await _fetchTurns(client, sessionId));
  }

  @override
  Future<void> createSession({String? title}) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    final created = await client.createSession(
      id: _sessionIdFactory(),
      title: title,
    );
    _setState(
      _state.copyWith(
        sessions: [..._state.sessions, created],
        activeSessionId: created.id,
      ),
    );
    _setTurns(created.id, await _fetchTurns(client, created.id));
  }

  @override
  Future<void> renameSession({
    required String sessionId,
    required String title,
  }) async {
    final client = _client;
    final trimmed = title.trim();
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Session title cannot be empty.',
      );
    }
    final updated = await client.updateSessionTitle(sessionId, title: trimmed);
    _setState(
      _state.copyWith(
        sessions: [
          for (final session in _state.sessions)
            if (session.id == updated.id) updated else session,
        ],
      ),
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    if (!_deletingSessionIds.add(sessionId)) {
      throw StateError('Hermes session delete is already in progress.');
    }
    try {
      await client.deleteSession(sessionId);
      final remaining = [
        for (final session in _state.sessions)
          if (session.id != sessionId) session,
      ];
      final wasActive = _state.activeSessionId == sessionId;
      final nextActiveId = wasActive
          ? remaining.firstOrNull?.id
          : _state.activeSessionId;
      final messages = Map<String, List<HermesChatTurn>>.from(_state.messages)
        ..remove(sessionId);
      if (wasActive &&
          nextActiveId != null &&
          !messages.containsKey(nextActiveId)) {
        try {
          messages[nextActiveId] = await _fetchTurns(client, nextActiveId);
        } catch (_) {
          messages[nextActiveId] = const [];
        }
      }
      _setState(
        _state.copyWith(
          sessions: remaining,
          activeSessionId: nextActiveId,
          clearActiveSessionId: nextActiveId == null,
          messages: messages,
        ),
      );
    } finally {
      _deletingSessionIds.remove(sessionId);
    }
  }

  @override
  Future<void> forkSession(String sessionId, {String? title}) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    final fork = await client.forkSession(
      sessionId,
      id: _sessionIdFactory(),
      title: title,
    );
    _setState(
      _state.copyWith(
        sessions: [..._state.sessions, fork],
        activeSessionId: fork.id,
      ),
    );
    _setTurns(fork.id, await _fetchTurns(client, fork.id));
  }

  @override
  Future<void> sendText(String text) async {
    final client = _client;
    final sessionId = _state.activeSessionId;
    if (client == null || sessionId == null) {
      throw StateError('Hermes channel is not connected to a session.');
    }

    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final now = DateTime.now();
    turns.add(
      HermesChatTurn(
        id: 'local-user-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.user,
        createdAt: now,
        text: text,
      ),
    );
    var assistantTurn = HermesChatTurn(
      id: 'local-assistant-${turns.length}',
      sessionId: sessionId,
      author: HermesTurnAuthor.assistant,
      createdAt: now,
      status: HermesTurnStatus.streaming,
    );
    turns.add(assistantTurn);
    var assistantIndex = turns.length - 1;
    _setTurns(sessionId, turns);

    final capabilities = _state.capabilities;
    final useRunTransport =
        capabilities != null &&
        HermesTransportPolicy(capabilities).supportsRunsTransport;

    final Stream<HermesStreamEvent> events;
    if (useRunTransport) {
      final run = await client.startRun(sessionId: sessionId, message: text);
      _activeRunId = run.id;
      events = client.runEvents(run.id);
    } else {
      events = client.streamSessionChat(sessionId, message: text);
    }

    final toolTurnIndexByCallId = <String, int>{};
    final completer = Completer<void>();
    var streamFailed = false;
    _activeStream = events.listen(
      (event) {
        final delta = event.delta;
        if (delta != null && delta.isNotEmpty) {
          assistantTurn = assistantTurn.appendDelta(delta);
          turns[assistantIndex] = assistantTurn;
          _setTurns(sessionId, List.of(turns));
          return;
        }
        if (_isToolEvent(event.name)) {
          _applyToolEvent(
            sessionId: sessionId,
            event: event,
            turns: turns,
            toolTurnIndexByCallId: toolTurnIndexByCallId,
            insertBefore: assistantIndex,
          );
          assistantIndex = turns.length - 1;
          _setTurns(sessionId, List.of(turns));
          return;
        }
        if (event.name == 'approval.request') {
          _approvalController.add(_approvalRequestFromEvent(event));
          return;
        }
        if (event.name == 'run.failed' || event.name == 'run.cancelled') {
          assistantTurn = assistantTurn.copyWith(
            status: HermesTurnStatus.failed,
          );
          turns[assistantIndex] = assistantTurn;
          _setTurns(sessionId, List.of(turns));
        }
      },
      onError: (Object error) {
        streamFailed = true;
        assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
        turns[assistantIndex] = assistantTurn;
        _setTurns(sessionId, List.of(turns));
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    await completer.future;
    _activeStream = null;
    _activeRunId = null;
    if (assistantTurn.status == HermesTurnStatus.streaming) {
      assistantTurn = assistantTurn.copyWith(
        status: HermesTurnStatus.completed,
      );
      turns[assistantIndex] = assistantTurn;
      _setTurns(sessionId, List.of(turns));
    }

    if (!streamFailed) {
      try {
        _setTurns(sessionId, await _fetchTurns(client, sessionId));
      } catch (_) {
        // Keep the locally streamed transcript; reconciliation is best-effort.
      }
    }
  }

  bool _isToolEvent(String name) {
    return name == 'tool.started' ||
        name == 'tool.completed' ||
        name == 'tool.failed';
  }

  /// Tracks tool progress by a `${runId}:${toolName}` call id (matching
  /// hermes-desktop's `chatToolEventFromRunEvent` synthesis, since Hermes run
  /// events don't carry a guaranteed-stable per-call id): the first event for
  /// a call id inserts a new turn just before the assistant reply; later
  /// events for the same call id update that turn in place instead of
  /// duplicating it.
  void _applyToolEvent({
    required String sessionId,
    required HermesStreamEvent event,
    required List<HermesChatTurn> turns,
    required Map<String, int> toolTurnIndexByCallId,
    required int insertBefore,
  }) {
    final toolName =
        navivoxOptionalStringFromJson(event.payload['tool']) ??
        navivoxOptionalStringFromJson(event.payload['tool_name']) ??
        'tool';
    final status = switch (event.name) {
      'tool.completed' => 'completed',
      'tool.failed' => 'failed',
      _ => 'running',
    };
    final preview = navivoxOptionalStringFromJson(event.payload['preview']);
    final result =
        navivoxOptionalStringFromJson(event.payload['result_text']) ??
        navivoxOptionalStringFromJson(event.payload['output']) ??
        navivoxOptionalStringFromJson(event.payload['result']);
    final callId = '$_activeRunId:$toolName';

    final existingIndex = toolTurnIndexByCallId[callId];
    if (existingIndex != null) {
      final existing = turns[existingIndex];
      turns[existingIndex] = existing.copyWith(
        toolCall: existing.toolCall!.copyWith(
          status: status,
          preview: preview,
          result: result,
        ),
      );
      return;
    }
    final turn = HermesChatTurn(
      id: 'tool-$callId',
      sessionId: sessionId,
      author: HermesTurnAuthor.system,
      createdAt: DateTime.now(),
      kind: HermesTurnKind.toolCall,
      toolCall: HermesToolCall(
        name: toolName,
        status: status,
        preview: preview,
        result: result,
      ),
    );
    turns.insert(insertBefore, turn);
    toolTurnIndexByCallId[callId] = insertBefore;
  }

  NavivoxApprovalRequest _approvalRequestFromEvent(HermesStreamEvent event) {
    return NavivoxApprovalRequest(
      id: navivoxOptionalStringFromJson(event.payload['approval_id']) ?? '',
      toolCallId:
          navivoxOptionalStringFromJson(event.payload['tool_call_id']) ?? '',
      prompt:
          navivoxOptionalStringFromJson(event.payload['prompt']) ??
          'Approval requested',
      risk: navivoxOptionalStringFromJson(event.payload['risk']),
    );
  }

  void _setTurns(String sessionId, List<HermesChatTurn> turns) {
    _setState(
      _state.copyWith(messages: {..._state.messages, sessionId: turns}),
    );
  }

  @override
  void cancelActiveTurn() {
    _activeStream?.cancel();
    _activeStream = null;
  }

  @override
  void stopActiveTurn() {
    final client = _client;
    final runId = _activeRunId;
    _activeStream?.cancel();
    _activeStream = null;
    _activeRunId = null;
    if (client != null && runId != null) {
      unawaited(client.stopRun(runId).catchError((_) {}));
    }
  }

  @override
  void respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  }) {
    final client = _client;
    final runId = _activeRunId;
    if (client == null || runId == null) return;
    unawaited(
      client.respondApproval(
        runId: runId,
        approvalId: approvalId,
        decision: decision.name,
      ),
    );
  }

  @override
  String startVoiceRun() {
    final id = 'voice-${_uuid.v4()}';
    final run = NavivoxVoiceRun.recording(
      id: id,
      serverId: 'hermes',
      profileId: _state.activeSessionId ?? '',
      createdAt: DateTime.now(),
    );
    _setState(
      _state.copyWith(
        voiceRuns: {..._state.voiceRuns, id: run},
        activeVoiceRunId: id,
      ),
    );
    return id;
  }

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    _updateVoiceRun(
      run.withDeviceTranscript(
        transcript: transcript,
        duration: duration,
        confidence: confidence,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  void submitVoiceRun(String voiceRunId) {
    final run = _state.voiceRuns[voiceRunId];
    final transcript = run?.transcript;
    if (run == null || transcript == null || transcript.isEmpty) return;
    _updateVoiceRun(
      run.markSubmitted(
        requestId: voiceRunId,
        sessionId: _state.activeSessionId,
      ),
    );
    sendText(transcript)
        .then((_) {
          final current = _state.voiceRuns[voiceRunId];
          if (current != null) _updateVoiceRun(current.markCompleted());
        })
        .catchError((Object error) {
          final current = _state.voiceRuns[voiceRunId];
          if (current != null) {
            _updateVoiceRun(current.markFailed(error.toString()));
          }
        });
  }

  @override
  void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    _updateVoiceRun(run.markCancelled(reason));
  }

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    _updateVoiceRun(run.markFailed(reason));
  }

  void _updateVoiceRun(NavivoxVoiceRun run) {
    _setState(_state.copyWith(voiceRuns: {..._state.voiceRuns, run.id: run}));
  }
}
