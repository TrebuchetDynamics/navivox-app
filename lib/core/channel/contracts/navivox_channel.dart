import 'package:flutter/foundation.dart';

import '../../gateway/navivox_gateway_protocol.dart';
import '../../protocol/navivox_memory.dart';
import '../../protocol/navivox_voice_run.dart';
import 'navivox_approval_request.dart';
import 'navivox_channel_state.dart';

export 'navivox_approval_request.dart';
export 'navivox_channel_state.dart';
export 'navivox_gateway_summary.dart';
export 'navivox_profile_contact.dart';

abstract interface class NavivoxChannel implements Listenable {
  NavivoxChannelState get state;
  Stream<NavivoxApprovalRequest> get approvalRequests;
  Future<void> connect({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  });
  Future<void> disconnect();
  void sendText(String text);
  void sendVoice({required String transcript});
  String startVoiceRun();
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
    NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  });
  void cancelVoiceRun(String voiceRunId, {String reason});
  void failVoiceRun(String voiceRunId, {required String reason});
  void submitVoiceRun(String voiceRunId);
  void cancelActiveTurn();
  void stopActiveTurn();
  void respondToApproval({required String approvalId, required bool approved});
  void requestAgentList();
  Future<NavivoxProfileSeedResult> profileSeed({
    required String seed,
    bool apply = false,
    List<String> workspaceRoots = const [],
  });
  Future<NavivoxVoiceProfilesResponse> voiceProfiles();
  Future<NavivoxVoiceProfileValidationResponse> validateVoiceProfile({
    required String profileId,
    required NavivoxProfileVoiceProfile voiceProfile,
  });
  Future<NavivoxRunRecordSnapshot> runRecord(String runIdOrSessionId);
  Future<NavivoxMemoryOverview> memoryOverview({
    String? serverId,
    String? profileId,
  });
  Future<NavivoxMemorySearchResult> memorySearch({
    String? serverId,
    String? profileId,
    String query,
    NavivoxMemoryType type,
    int limit,
    String? pageToken,
  });
  Future<NavivoxMemoryDetail> memoryDetail({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  });
  Future<NavivoxMemoryActionResult> memoryAction({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
    required NavivoxMemoryActionType action,
    String? correction,
  });
  void selectAgent(String agentId);
  void selectProfileContact({
    required String serverId,
    required String profileId,
  });
  void selectProfileRouting({
    String? workspace,
    String? provider,
    String? channel,
  });
  bool get configAdminAvailable;
  bool get configAdminSupported;
  bool get configAdminLoadFailed;
  Future<void> refreshConfigAdmin();
  Future<NavivoxConfigAdminResponse> diffConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  );
  Future<NavivoxConfigAdminResponse> validateConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  );
  Future<NavivoxConfigAdminResponse> applyConfigAdmin(
    List<NavivoxConfigAdminChange> changes,
  );
  void sendConfigSet({required String field, required Object? value});
  void sendConfigSecretSet({required String name, required String secret});
}
