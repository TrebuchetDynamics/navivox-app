import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

class TestNavivoxChannel extends ChangeNotifier implements NavivoxChannel {
  TestNavivoxChannel({
    NavivoxChannelState initial = const NavivoxChannelState(),
  }) : _state = initial;

  NavivoxChannelState _state;
  final StreamController<NavivoxApprovalRequest> _approvals =
      StreamController<NavivoxApprovalRequest>.broadcast();
  int _messageCounter = 0;

  final List<String> sentTexts = [];
  final List<({String text, String? serverId, String? profileId})>
  sentTextCalls = [];
  final List<String> sentVoiceTranscripts = [];
  int cancelRequests = 0;
  int stopRequests = 0;
  final List<({String approvalId, bool approved})> approvalResponses = [];
  final List<({String field, Object? value})> configSetCalls = [];
  final List<({String name, String secret})> configSecretSetCalls = [];
  final List<List<NavivoxConfigAdminChange>> configAdminValidateCalls = [];
  final List<List<NavivoxConfigAdminChange>> configAdminDiffCalls = [];
  final List<List<NavivoxConfigAdminChange>> configAdminApplyCalls = [];
  bool _configAdminAvailable = false;
  NavivoxConfigAdminResponse? _configAdminValidate;
  NavivoxConfigAdminResponse? _configAdminDiff;
  NavivoxConfigAdminResponse? _configAdminApply;
  String? lastSelectedAgentId;
  ({String serverId, String profileId})? selectedProfileScope;
  int agentListRequests = 0;
  NavivoxMemoryOverview? _memoryOverview;
  NavivoxProfileSeedResult? _profileSeedDraft;
  NavivoxProfileSeedResult? _profileSeedApply;
  NavivoxVoiceProfilesResponse? _voiceProfiles;
  NavivoxVoiceProfileValidationResponse? _voiceProfileValidation;
  NavivoxRunRecordSnapshot? _runRecord;
  NavivoxMemorySearchResult? _memorySearch;
  NavivoxMemoryDetail? _memoryDetail;
  NavivoxMemoryActionResult? _memoryActionResult;
  final List<
    ({
      String? serverId,
      String? profileId,
      String query,
      NavivoxMemoryType type,
      int limit,
      String? pageToken,
    })
  >
  memorySearchCalls = [];
  final List<
    ({String? serverId, String? profileId, String id, NavivoxMemoryType type})
  >
  memoryDetailCalls = [];
  final List<
    ({
      String? serverId,
      String? profileId,
      String id,
      NavivoxMemoryType type,
      NavivoxMemoryActionType action,
      String? correction,
    })
  >
  memoryActionCalls = [];
  final List<({String seed, bool apply, List<String> workspaceRoots})>
  profileSeedCalls = [];
  int voiceProfileRequests = 0;
  final List<({String profileId, NavivoxProfileVoiceProfile voiceProfile})>
  voiceProfileValidateCalls = [];
  final List<String> runRecordCalls = [];

  @override
  NavivoxChannelState get state => _state;

  set state(NavivoxChannelState next) {
    _state = next;
    notifyListeners();
  }

  void seedAgents(List<NavivoxAgent> agents, {String? selectedAgentId}) {
    state = _state.copyWith(
      agents: agents,
      selectedAgentId: selectedAgentId ?? _state.selectedAgentId,
    );
  }

  void seedServers(List<NavivoxServer> servers, {String? activeServerId}) {
    state = _state.copyWith(
      servers: servers,
      activeServerId: activeServerId ?? _state.activeServerId,
    );
  }

  void seedProfileContacts(
    List<NavivoxProfileContact> contacts, {
    String? selectedKey,
  }) {
    state = _state.copyWith(
      profileContacts: contacts,
      selectedProfileContactKey:
          selectedKey ?? _state.selectedProfileContactKey,
    );
  }

  void seedMessages(List<NavivoxChatMessage> messages) {
    final map = <String, NavivoxChatMessage>{};
    for (final m in messages) {
      map[m.id] = m;
    }
    state = _state.copyWith(messages: map);
  }

  void seedVoiceRuns(List<NavivoxVoiceRun> runs) {
    final map = <String, NavivoxVoiceRun>{};
    for (final run in runs) {
      map[run.id] = run;
    }
    state = _state.copyWith(
      voiceRuns: map,
      activeVoiceRunId: runs.isEmpty ? null : runs.last.id,
    );
  }

  void emitApprovalRequest(NavivoxApprovalRequest request) {
    _approvals.add(request);
  }

  void emitConfigSchema(Map<String, Object?> schema) {
    state = _state.copyWith(configSchema: schema);
  }

  void emitConfigValues(Map<String, Object?> values) {
    state = _state.copyWith(configValues: values);
  }

  void emitConfigDiff(Map<String, Object?> diff) {
    state = _state.copyWith(configDiff: diff);
  }

  void seedMemoryOverview(NavivoxMemoryOverview overview) {
    _memoryOverview = overview;
  }

  void seedProfileSeedResults({
    required NavivoxProfileSeedResult draft,
    required NavivoxProfileSeedResult apply,
  }) {
    _profileSeedDraft = draft;
    _profileSeedApply = apply;
  }

  void seedVoiceProfiles(NavivoxVoiceProfilesResponse response) {
    _voiceProfiles = response;
  }

  void seedVoiceProfileValidation(
    NavivoxVoiceProfileValidationResponse response,
  ) {
    _voiceProfileValidation = response;
  }

  void seedRunRecord(NavivoxRunRecordSnapshot record) {
    _runRecord = record;
  }

  void seedConfigAdminResponses({
    required NavivoxConfigAdminResponse validate,
    required NavivoxConfigAdminResponse diff,
    required NavivoxConfigAdminResponse apply,
  }) {
    _configAdminAvailable = true;
    _configAdminValidate = validate;
    _configAdminDiff = diff;
    _configAdminApply = apply;
  }

  void seedMemorySearch(NavivoxMemorySearchResult result) {
    _memorySearch = result;
  }

  void seedMemoryDetail(NavivoxMemoryDetail detail) {
    _memoryDetail = detail;
  }

  void seedMemoryActionResult(NavivoxMemoryActionResult result) {
    _memoryActionResult = result;
  }

  @override
  Stream<NavivoxApprovalRequest> get approvalRequests => _approvals.stream;

  @override
  Future<void> connect({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  }) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    sentTexts.add(trimmed);
    final active = _state.activeProfileContact;
    sentTextCalls.add((
      text: trimmed,
      serverId: active?.serverId,
      profileId: active?.profileId,
    ));
    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    messages['test-user-${++_messageCounter}'] = NavivoxChatMessage(
      id: 'test-user-$_messageCounter',
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.text,
      createdAt: DateTime.utc(2026, 5, 16, 12, 0, _messageCounter),
      text: trimmed,
    );
    state = _state.copyWith(messages: messages);
  }

  @override
  void sendVoice({required String transcript}) {
    sentVoiceTranscripts.add(transcript);
  }

  @override
  String startVoiceRun() {
    final active = _state.activeProfileContact;
    final id = 'test-voice-${++_messageCounter}';
    final run = NavivoxVoiceRun.recording(
      id: id,
      serverId: active?.serverId ?? 'navivox-gateway',
      profileId: active?.profileId ?? 'default',
      createdAt: DateTime.utc(2026, 5, 16, 12, 0, _messageCounter),
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
      updatedAt: DateTime.utc(2026, 5, 16, 12, 1),
    );
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void cancelVoiceRun(
    String voiceRunId, {
    String reason = 'cancelled before send',
  }) {
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
    sentVoiceTranscripts.add(transcript);
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.markSubmitted(requestId: 'test-request-$voiceRunId');
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void cancelActiveTurn() {
    cancelRequests += 1;
  }

  @override
  void stopActiveTurn() {
    stopRequests += 1;
  }

  @override
  void respondToApproval({required String approvalId, required bool approved}) {
    approvalResponses.add((approvalId: approvalId, approved: approved));
  }

  @override
  void requestAgentList() => agentListRequests += 1;

  @override
  Future<NavivoxProfileSeedResult> profileSeed({
    required String seed,
    bool apply = false,
    List<String> workspaceRoots = const [],
  }) async {
    final normalizedRoots = workspaceRoots
        .map((root) => root.trim())
        .where((root) => root.isNotEmpty)
        .toList(growable: false);
    profileSeedCalls.add((
      seed: seed.trim(),
      apply: apply,
      workspaceRoots: normalizedRoots,
    ));
    final result = apply ? _profileSeedApply : _profileSeedDraft;
    if (result == null) {
      throw StateError('profile seed result not seeded');
    }
    if (apply && result.contact.isNotEmpty) {
      final contact = _profileContactFromJson(result.contact);
      final contacts = [..._state.profileContacts];
      final index = contacts.indexWhere(
        (existing) => existing.key == contact.key,
      );
      if (index >= 0) {
        contacts[index] = contact;
      } else {
        contacts.add(contact);
      }
      final servers = _upsertServer(_state.servers, contact);
      state = _state.copyWith(
        servers: servers,
        activeServerId: contact.serverId,
        profileContacts: contacts,
        selectedProfileContactKey: contact.key,
      );
    }
    return result;
  }

  @override
  Future<NavivoxVoiceProfilesResponse> voiceProfiles() async {
    voiceProfileRequests += 1;
    return _voiceProfiles ??
        const NavivoxVoiceProfilesResponse(
          action: 'voice_profiles.get',
          providerMatrix: NavivoxVoiceProviderMatrix(),
        );
  }

  @override
  Future<NavivoxVoiceProfileValidationResponse> validateVoiceProfile({
    required String profileId,
    required NavivoxProfileVoiceProfile voiceProfile,
  }) async {
    voiceProfileValidateCalls.add((
      profileId: profileId.trim(),
      voiceProfile: NavivoxProfileVoiceProfile.fromJson(voiceProfile.toJson()),
    ));
    return _voiceProfileValidation ??
        NavivoxVoiceProfileValidationResponse(
          action: 'voice_profiles.validate',
          providerMatrix: const NavivoxVoiceProviderMatrix(),
          valid: true,
          validation: NavivoxVoiceProfileValidation(
            profileId: profileId.trim(),
            voiceProfile: voiceProfile,
            valid: true,
          ),
        );
  }

  @override
  Future<NavivoxRunRecordSnapshot> runRecord(String runIdOrSessionId) async {
    final id = runIdOrSessionId.trim();
    runRecordCalls.add(id);
    return _runRecord ??
        NavivoxRunRecordSnapshot(
          runId: id,
          sessionId: '',
          status: 'unavailable',
          createdAt: null,
          updatedAt: null,
          completedAt: null,
          raw: const {},
        );
  }

  @override
  Future<NavivoxMemoryOverview> memoryOverview({
    String? serverId,
    String? profileId,
  }) async {
    final active = _state.activeProfileContact;
    return _memoryOverview ??
        NavivoxMemoryOverview.degraded(
          profileId: profileId ?? active?.profileId ?? 'default',
          reason: 'Gormes memory API is unavailable.',
        );
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
    final active = _state.activeProfileContact;
    memorySearchCalls.add((
      serverId: serverId ?? active?.serverId,
      profileId: profileId ?? active?.profileId,
      query: query,
      type: type,
      limit: limit,
      pageToken: pageToken,
    ));
    return _memorySearch ??
        const NavivoxMemorySearchResult.degraded(
          reason: 'Gormes memory search API is unavailable.',
        );
  }

  @override
  Future<NavivoxMemoryDetail> memoryDetail({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  }) async {
    final active = _state.activeProfileContact;
    memoryDetailCalls.add((
      serverId: serverId ?? active?.serverId,
      profileId: profileId ?? active?.profileId,
      id: id,
      type: type,
    ));
    return _memoryDetail ??
        NavivoxMemoryDetail.degraded(
          id: id,
          reason: 'Gormes memory detail API is unavailable.',
        );
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
    final active = _state.activeProfileContact;
    memoryActionCalls.add((
      serverId: serverId ?? active?.serverId,
      profileId: profileId ?? active?.profileId,
      id: id,
      type: type,
      action: action,
      correction: correction?.trim(),
    ));
    return _memoryActionResult ??
        NavivoxMemoryActionResult(
          accepted: true,
          action: action,
          message: '${action.label} requested.',
        );
  }

  @override
  void selectAgent(String agentId) {
    lastSelectedAgentId = agentId;
    state = _state.copyWith(selectedAgentId: agentId);
  }

  @override
  void selectProfileContact({
    required String serverId,
    required String profileId,
  }) {
    selectedProfileScope = (serverId: serverId, profileId: profileId);
    state = _state.copyWith(
      activeServerId: serverId,
      selectedProfileContactKey: '$serverId::$profileId',
    );
  }

  @override
  void selectProfileRouting({
    String? workspace,
    String? provider,
    String? channel,
  }) {
    state = _state.withActiveProfileRouting(
      workspace: workspace,
      provider: provider,
      channel: channel,
    );
  }

  @override
  bool get configAdminAvailable => _configAdminAvailable;

  @override
  Future<void> refreshConfigAdmin() async {}

  @override
  Future<NavivoxConfigAdminResponse> validateConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final copied = _copyConfigAdminChanges(changes);
    configAdminValidateCalls.add(copied);
    final response =
        _configAdminValidate ??
        const NavivoxConfigAdminResponse(
          action: 'config.validate',
          valid: true,
        );
    state = _state.copyWith(configDiff: response.snapshot);
    return response;
  }

  @override
  Future<NavivoxConfigAdminResponse> diffConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final copied = _copyConfigAdminChanges(changes);
    configAdminDiffCalls.add(copied);
    final response =
        _configAdminDiff ??
        const NavivoxConfigAdminResponse(action: 'config.diff', valid: true);
    state = _state.copyWith(configDiff: response.snapshot);
    return response;
  }

  @override
  Future<NavivoxConfigAdminResponse> applyConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  ) async {
    final copied = _copyConfigAdminChanges(changes);
    configAdminApplyCalls.add(copied);
    final response =
        _configAdminApply ??
        const NavivoxConfigAdminResponse(
          action: 'config.apply',
          valid: true,
          applied: true,
        );
    state = _state.copyWith(configDiff: response.snapshot);
    return response;
  }

  @override
  void sendConfigSet({required String field, required Object? value}) {
    configSetCalls.add((field: field, value: value));
  }

  @override
  void sendConfigSecretSet({required String name, required String secret}) {
    configSecretSetCalls.add((name: name, secret: secret));
  }

  List<NavivoxConfigAdminChange> _copyConfigAdminChanges(
    List<NavivoxConfigAdminChange> changes,
  ) {
    return changes
        .map(
          (change) => NavivoxConfigAdminChange(
            key: change.key,
            value: change.value,
            delete: change.delete,
          ),
        )
        .toList(growable: false);
  }

  NavivoxProfileContact _profileContactFromJson(Map<String, Object?> json) {
    final serverId = _stringField(json, 'server_id', fallback: 'local');
    final profileId = _stringField(json, 'profile_id', fallback: 'default');
    return NavivoxProfileContact(
      serverId: serverId,
      profileId: profileId,
      displayName: _stringField(json, 'display_name', fallback: profileId),
      serverLabel: _stringField(json, 'server_label', fallback: serverId),
      health: _profileHealthFromJson(json['health']),
      latestPreview: _stringField(
        json,
        'latest_preview',
        fallback: 'Profile ready',
      ),
      latestPreviewKind: _stringField(
        json,
        'latest_preview_kind',
        fallback: 'status',
      ),
      workspaceRootCount: _intField(json, 'workspace_root_count'),
      workspaceRootsOk: _boolField(json, 'workspace_roots_ok', fallback: true),
      workspaceRootsWarning: _intField(json, 'workspace_roots_warning'),
      workspaceRootsError: _intField(json, 'workspace_roots_error'),
      attentionBadges: _stringListField(json, 'attention_badges'),
      micAvailable: _boolField(json, 'mic_available'),
      activeTurnState: _stringField(
        json,
        'active_turn_state',
        fallback: 'idle',
      ),
      avatarSeed: _stringField(
        json,
        'avatar_seed',
        fallback: '$serverId:$profileId',
      ),
    );
  }

  List<NavivoxServer> _upsertServer(
    List<NavivoxServer> servers,
    NavivoxProfileContact contact,
  ) {
    if (servers.any((server) => server.id == contact.serverId)) {
      return servers;
    }
    return [
      ...servers,
      NavivoxServer(
        id: contact.serverId,
        name: contact.serverLabel,
        status: 'online',
      ),
    ];
  }

  NavivoxProfileHealth _profileHealthFromJson(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'offline' => NavivoxProfileHealth.offline,
      'needs_auth' ||
      'needs-auth' ||
      'needsauth' => NavivoxProfileHealth.needsAuth,
      'warning' => NavivoxProfileHealth.warning,
      _ => NavivoxProfileHealth.online,
    };
  }

  String _stringField(
    Map<String, Object?> json,
    String key, {
    required String fallback,
  }) {
    final text = json[key]?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  int _intField(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _boolField(
    Map<String, Object?> json,
    String key, {
    bool fallback = false,
  }) {
    final value = json[key];
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }

  List<String> _stringListField(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  void dispose() {
    _approvals.close();
    super.dispose();
  }
}
