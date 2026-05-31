import 'package:navivox/core/protocol/navivox_voice_run.dart';

/// Shared Voice run value fixture for chat presentation/conversation tests.
NavivoxVoiceRun chatVoiceRun({
  String id = 'voice-1',
  String serverId = 'local',
  String profileId = 'mineru',
  NavivoxVoiceRunStatus status = NavivoxVoiceRunStatus.pendingSend,
  NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  NavivoxTtsStatus ttsStatus = NavivoxTtsStatus.unavailable,
  String transcript = 'ship this safely',
  Duration? duration,
  double? confidence,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final timestamp = createdAt ?? DateTime.utc(2026, 5, 23, 9);
  return NavivoxVoiceRun(
    id: id,
    serverId: serverId,
    profileId: profileId,
    status: status,
    transcriptSource: transcriptSource,
    ttsStatus: ttsStatus,
    transcript: transcript,
    duration: duration,
    confidence: confidence,
    createdAt: timestamp,
    updatedAt: updatedAt ?? timestamp,
  );
}
