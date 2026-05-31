import 'package:navivox/core/protocol/navivox_voice_run.dart';

NavivoxVoiceRun recordingVoiceRun({
  String id = 'voice-1',
  String serverId = 'local',
  String profileId = 'mineru',
  DateTime? createdAt,
}) {
  return NavivoxVoiceRun.recording(
    id: id,
    serverId: serverId,
    profileId: profileId,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 21, 12),
  );
}
