import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/models/hermes_chat_turn.dart';
import 'package:navivox/core/hermes/models/hermes_session.dart';
import 'package:navivox/core/protocol/voice/models/navivox_voice_run.dart';

class FakeHermesConnectCall {
  const FakeHermesConnectCall({required this.baseUrl, this.apiKey});

  final String baseUrl;
  final String? apiKey;
}

/// Lightweight [HermesChannel] test double: an in-memory session with no real
/// HTTP/SSE transport, used by controller and widget tests. `sendText` and
/// voice-run submission both append a user turn plus an immediate, completed
/// assistant echo turn so transcript/continuous-voice behavior is testable
/// without a real streaming server.
class FakeHermesChannel extends ChangeNotifier implements HermesChannel {
  FakeHermesChannel({
    HermesConnectionStatus status = HermesConnectionStatus.connected,
    String sessionId = 'sess_1',
    String? errorMessage,
  }) : _state = status == HermesConnectionStatus.connected
           ? HermesChannelState(
               status: status,
               sessions: [HermesSession(id: sessionId, source: 'fake')],
               activeSessionId: sessionId,
               messages: {sessionId: const []},
             )
           : HermesChannelState(status: status, errorMessage: errorMessage);

  factory FakeHermesChannel.disconnected() =>
      FakeHermesChannel(status: HermesConnectionStatus.disconnected);

  final List<FakeHermesConnectCall> connectCalls = [];
  final List<String> sentVoiceTranscripts = [];
  final List<Map<String, Object?>> respondToApprovalCalls = [];
  int stopActiveTurnCalls = 0;
  final _approvalController =
      StreamController<NavivoxApprovalRequest>.broadcast();

  HermesChannelState _state;

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
    connectCalls.add(FakeHermesConnectCall(baseUrl: baseUrl, apiKey: apiKey));
    const sessionId = 'sess_1';
    _setState(
      HermesChannelState(
        status: HermesConnectionStatus.connected,
        sessions: [const HermesSession(id: sessionId, source: 'fake')],
        activeSessionId: sessionId,
        messages: const {sessionId: []},
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    _setState(const HermesChannelState());
  }

  @override
  Future<void> selectSession(String sessionId) async {
    _setState(_state.copyWith(activeSessionId: sessionId));
  }

  @override
  Future<void> createSession({String? title}) async {}

  @override
  Future<void> sendText(String text) async {
    _appendExchange(text);
  }

  void emitApprovalRequest(NavivoxApprovalRequest request) {
    _approvalController.add(request);
  }

  /// Test-only helper: leaves an assistant turn `streaming` (as a real
  /// in-flight run would) so widget tests can exercise the stop control.
  void beginStreamingTurn(String userText) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final now = DateTime.now();
    turns.add(
      HermesChatTurn(
        id: 'user-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.user,
        createdAt: now,
        text: userText,
      ),
    );
    turns.add(
      HermesChatTurn(
        id: 'assistant-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.assistant,
        createdAt: now,
        status: HermesTurnStatus.streaming,
      ),
    );
    _setState(
      _state.copyWith(messages: {..._state.messages, sessionId: turns}),
    );
  }

  void addToolCallTurn(HermesToolCall toolCall) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    turns.add(
      HermesChatTurn(
        id: 'tool-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.system,
        createdAt: DateTime.now(),
        kind: HermesTurnKind.toolCall,
        toolCall: toolCall,
      ),
    );
    _setState(
      _state.copyWith(messages: {..._state.messages, sessionId: turns}),
    );
  }

  void _appendExchange(String text) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final now = DateTime.now();
    turns.add(
      HermesChatTurn(
        id: 'user-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.user,
        createdAt: now,
        text: text,
      ),
    );
    turns.add(
      HermesChatTurn(
        id: 'assistant-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.assistant,
        createdAt: now,
        text: 'echo: $text',
      ),
    );
    _setState(
      _state.copyWith(messages: {..._state.messages, sessionId: turns}),
    );
  }

  @override
  void cancelActiveTurn() {}

  @override
  void stopActiveTurn() {
    stopActiveTurnCalls += 1;
  }

  @override
  void respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  }) {
    respondToApprovalCalls.add({
      'approvalId': approvalId,
      'decision': decision,
    });
  }

  @override
  String startVoiceRun() {
    final id = 'voice-${_state.voiceRuns.length}';
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
    sentVoiceTranscripts.add(transcript);
    _appendExchange(transcript);
    _updateVoiceRun(_state.voiceRuns[voiceRunId]!.markCompleted());
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
