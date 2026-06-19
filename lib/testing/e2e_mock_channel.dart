import 'dart:async';

import 'package:flutter/material.dart';

import '../core/channel/navivox_channel.dart';
import '../core/gateway/navivox_gateway_protocol.dart';
import '../core/protocol/navivox_event.dart';
import '../core/protocol/navivox_memory.dart';
import '../core/protocol/navivox_voice_run.dart';

enum E2EConfigAdminMode { unsupported, loadFailed, available }

// Mock schema matching gormes configAdminSchema() output.
const Map<String, Object?> _mockConfigSchema = {
  'fields': [
    {'key': 'navivox.enabled', 'path': 'navivox.enabled', 'title': 'Enable Navivox', 'label': 'Enable Navivox', 'type': 'bool', 'reload': 'restart_or_reload'},
    {'key': 'navivox.bind_host', 'path': 'navivox.bind_host', 'title': 'Bind host', 'label': 'Bind host', 'type': 'string', 'reload': 'restart_or_reload'},
    {'key': 'navivox.port', 'path': 'navivox.port', 'title': 'Port', 'label': 'Port', 'type': 'int', 'reload': 'restart_or_reload'},
    {'key': 'navivox.exposure_mode', 'path': 'navivox.exposure_mode', 'title': 'Exposure mode', 'label': 'Exposure mode', 'type': 'enum', 'allowed': ['local', 'tailscale', 'wireguard', 'vpn', 'public'], 'reload': 'restart_or_reload'},
    {'key': 'navivox.auth_mode', 'path': 'navivox.auth_mode', 'title': 'Auth mode', 'label': 'Auth mode', 'type': 'enum', 'allowed': ['pairing_token', 'static_token', 'tailscale_identity', 'token_and_tailscale_identity'], 'reload': 'restart_or_reload'},
    {'key': 'navivox.token', 'path': 'navivox.token', 'title': 'Pairing/static token', 'label': 'Pairing/static token', 'type': 'secret', 'secret': true, 'actions': ['set', 'rotate', 'delete', 'test'], 'reload': 'restart_or_reload'},
  ],
};

const Map<String, Object?> _mockConfigValues = {
  'navivox.enabled': true,
  'navivox.bind_host': '127.0.0.1',
  'navivox.port': 8765,
  'navivox.exposure_mode': 'local',
  'navivox.auth_mode': 'pairing_token',
  'navivox.token': {'secret_status': 'set', 'source': 'env:GORMES_NAVIVOX_TOKEN'},
};

class E2EMockChannel extends ChangeNotifier implements NavivoxChannel {
  NavivoxChannelState _state = const NavivoxChannelState();
  final StreamController<NavivoxApprovalRequest> _approvals =
      StreamController<NavivoxApprovalRequest>.broadcast();
  int _messageCounter = 0;
  int _voiceRunCounter = 0;
  E2EConfigAdminMode _configAdminMode = E2EConfigAdminMode.unsupported;

  void setConfigAdminMode(E2EConfigAdminMode mode) {
    _configAdminMode = mode;
    if (mode == E2EConfigAdminMode.available) {
      _state = _state.copyWith(
        configSchema: _mockConfigSchema,
        configValues: _mockConfigValues,
      );
    } else {
      _state = _state.copyWith(clearConfigSchema: true, configValues: const {});
    }
    notifyListeners();
  }

  @override
  NavivoxChannelState get state => _state;

  set state(NavivoxChannelState next) {
    _state = next;
    notifyListeners();
  }

  @override
  Stream<NavivoxApprovalRequest> get approvalRequests => _approvals.stream;

  @override
  Future<void> connect({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  }) async {
    _state = _state.copyWith(
      servers: const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
        NavivoxServer(id: 'office', name: 'Office Gormes', status: 'online'),
      ],
      activeServerId: 'local',
      profileContacts: [
        const NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready to work on mineru',
          micAvailable: true,
        ),
        const NavivoxProfileContact(
          serverId: 'office',
          profileId: 'support',
          displayName: 'Support Triage',
          serverLabel: 'office',
          health: NavivoxProfileHealth.needsAuth,
          latestPreview: 'Waiting for auth',
          attentionBadges: ['auth'],
        ),
        const NavivoxProfileContact(
          serverId: 'local',
          profileId: 'voice',
          displayName: 'Voice Agent',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Voice ready',
          micAvailable: true,
        ),
      ],
      selectedProfileContactKey: 'local::mineru',
    );
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    state = const NavivoxChannelState();
  }

  @override
  void sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final active = _state.activeProfileContact;
    final serverId = active?.serverId ?? _state.activeServerId;
    final profileId = active?.profileId;
    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    final id = 'user-${messages.length + 1}';
    messages[id] = NavivoxChatMessage(
      id: id,
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.text,
      createdAt: DateTime.now(),
      text: trimmed,
      serverId: serverId,
      profileId: profileId,
    );
    final aid = 'assistant-${messages.length + 1}';
    messages[aid] = NavivoxChatMessage(
      id: aid,
      author: NavivoxMessageAuthor.assistant,
      kind: NavivoxMessageKind.text,
      createdAt: DateTime.now(),
      text: 'Echo: $trimmed',
      serverId: serverId,
      profileId: profileId,
    );
    _state = _state.copyWith(messages: messages);
    notifyListeners();
  }

  @override
  void sendVoice({required String transcript}) {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) return;
    final id = startVoiceRun();
    stageVoiceRunTranscript(
      voiceRunId: id,
      transcript: trimmed,
      duration: Duration.zero,
      confidence: 1,
    );
    submitVoiceRun(id);
  }

  @override
  String startVoiceRun() {
    final active = _state.activeProfileContact;
    final id = 'e2e-voice-${++_voiceRunCounter}';
    final run = NavivoxVoiceRun.recording(
      id: id,
      serverId: active?.serverId ?? _state.activeServerId ?? 'local',
      profileId: active?.profileId ?? 'mineru',
      createdAt: DateTime.now(),
    );
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[id] = run;
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: id);
    return id;
  }

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
    NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.copyWith(
      status: NavivoxVoiceRunStatus.pendingSend,
      transcriptSource: transcriptSource,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      updatedAt: DateTime.now(),
    );
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.markCancelled(reason);
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.markFailed(reason);
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void submitVoiceRun(String voiceRunId) {
    final run = _state.voiceRuns[voiceRunId];
    final transcript = run?.transcript?.trim() ?? '';
    if (run == null || transcript.isEmpty) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.markSubmitted(requestId: 'e2e-request-$voiceRunId');
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);

    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    final userId = 'voice-user-${++_messageCounter}';
    messages[userId] = NavivoxChatMessage(
      id: userId,
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.voice,
      createdAt: DateTime.now(),
      text: transcript,
      serverId: run.serverId,
      profileId: run.profileId,
      voice: NavivoxVoiceMessage(
        voiceRunId: voiceRunId,
        transcript: transcript,
        duration: run.duration ?? Duration.zero,
        confidence: run.confidence ?? 1,
      ),
    );
    final assistantId = 'voice-assistant-${++_messageCounter}';
    messages[assistantId] = NavivoxChatMessage(
      id: assistantId,
      author: NavivoxMessageAuthor.assistant,
      kind: NavivoxMessageKind.text,
      createdAt: DateTime.now(),
      text: 'Echo: $transcript',
      serverId: run.serverId,
      profileId: run.profileId,
    );
    state = _state.copyWith(messages: messages);
  }

  @override
  void cancelActiveTurn() {}

  @override
  void stopActiveTurn() {}

  @override
  void respondToApproval({
    required String approvalId,
    required bool approved,
  }) {}

  @override
  void requestAgentList() {}

  @override
  Future<NavivoxProfileSeedResult> profileSeed({
    required String seed,
    bool apply = false,
    List<String> workspaceRoots = const [],
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxVoiceProfilesResponse> voiceProfiles() async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxVoiceProfileValidationResponse> validateVoiceProfile({
    required String profileId,
    required NavivoxProfileVoiceProfile voiceProfile,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxRunRecordSnapshot> runRecord(String runIdOrSessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxMemoryOverview> memoryOverview({
    String? serverId,
    String? profileId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxMemorySearchResult> memorySearch({
    String? serverId,
    String? profileId,
    String query = '',
    NavivoxMemoryType type = NavivoxMemoryType.all,
    int limit = 20,
    String? pageToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxMemoryDetail> memoryDetail({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxMemoryActionResult> memoryAction({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
    required NavivoxMemoryActionType action,
    String? correction,
  }) async {
    throw UnimplementedError();
  }

  @override
  void selectAgent(String agentId) {}

  @override
  void selectProfileContact({
    required String serverId,
    required String profileId,
  }) {
    final contact = _state.profileContacts
        .where((c) => c.serverId == serverId && c.profileId == profileId)
        .firstOrNull;
    if (contact != null) {
      _state = _state.copyWith(
        activeServerId: serverId,
        selectedProfileContactKey: contact.key,
      );
      notifyListeners();
    }
  }

  @override
  void selectProfileRouting({
    String? workspace,
    String? provider,
    String? channel,
  }) {}

  @override
  bool get configAdminAvailable => _configAdminMode == E2EConfigAdminMode.available;

  @override
  bool get configAdminSupported => _configAdminMode != E2EConfigAdminMode.unsupported;

  @override
  bool get configAdminLoadFailed => _configAdminMode == E2EConfigAdminMode.loadFailed;

  @override
  Future<void> refreshConfigAdmin() async {}

  @override
  Future<NavivoxConfigAdminResponse> diffConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxConfigAdminResponse> validateConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NavivoxConfigAdminResponse> applyConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  void sendConfigSet({required String field, required Object? value}) {}

  @override
  void sendConfigSecretSet({required String name, required String secret}) {}

  @override
  void dispose() {
    _approvals.close();
    super.dispose();
  }
}
