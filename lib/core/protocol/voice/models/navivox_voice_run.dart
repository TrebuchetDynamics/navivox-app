export '../contracts/navivox_voice_status.dart';

import '../contracts/navivox_voice_status.dart';

class NavivoxVoiceRun {
  const NavivoxVoiceRun({
    required this.id,
    required this.serverId,
    required this.profileId,
    required this.status,
    required this.transcriptSource,
    required this.ttsStatus,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
    this.requestId,
    this.transcript,
    this.duration,
    this.confidence,
    this.reason,
    this.retentionPolicy = 'transcript_only',
  });

  factory NavivoxVoiceRun.recording({
    required String id,
    required String serverId,
    required String profileId,
    required DateTime createdAt,
  }) {
    return NavivoxVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      status: NavivoxVoiceRunStatus.recording,
      transcriptSource: NavivoxTranscriptSource.device,
      ttsStatus: NavivoxTtsStatus.unavailable,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  final String id;
  final String serverId;
  final String profileId;
  final String? sessionId;
  final String? requestId;
  final NavivoxVoiceRunStatus status;
  final NavivoxTranscriptSource transcriptSource;
  final NavivoxTtsStatus ttsStatus;
  final String? transcript;
  final Duration? duration;
  final double? confidence;
  final String? reason;
  final String retentionPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => navivoxVoiceRunStatusIsTerminal(status);

  NavivoxVoiceRun withDeviceTranscript({
    required String transcript,
    required Duration duration,
    required double confidence,
    required DateTime updatedAt,
  }) {
    return copyWith(
      status: NavivoxVoiceRunStatus.pendingSend,
      transcriptSource: NavivoxTranscriptSource.device,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      updatedAt: updatedAt,
    );
  }

  NavivoxVoiceRun markSubmitted({
    required String requestId,
    String? sessionId,
  }) {
    return _withLifecycleStatus(
      status: NavivoxVoiceRunStatus.submitted,
      requestId: requestId,
      replaceRequestId: true,
      sessionId: sessionId,
      replaceSessionId: true,
      clearReason: true,
    );
  }

  NavivoxVoiceRun markCompleted() {
    return _withLifecycleStatus(
      status: NavivoxVoiceRunStatus.completed,
      clearReason: true,
    );
  }

  NavivoxVoiceRun markCancelled(String reason) {
    return _withLifecycleStatus(
      status: NavivoxVoiceRunStatus.cancelled,
      reason: reason,
    );
  }

  NavivoxVoiceRun markFailed(String reason) {
    return _withLifecycleStatus(
      status: NavivoxVoiceRunStatus.failed,
      reason: reason,
    );
  }

  NavivoxVoiceRun _withLifecycleStatus({
    required NavivoxVoiceRunStatus status,
    String? sessionId,
    bool replaceSessionId = false,
    String? requestId,
    bool replaceRequestId = false,
    String? reason,
    bool clearReason = false,
  }) {
    assert(
      !clearReason || reason == null,
      'A voice-run transition cannot set and clear reason at the same time.',
    );
    return NavivoxVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      sessionId: replaceSessionId ? sessionId : this.sessionId,
      requestId: replaceRequestId ? requestId : this.requestId,
      status: status,
      transcriptSource: transcriptSource,
      ttsStatus: ttsStatus,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      reason: clearReason ? null : reason ?? this.reason,
      retentionPolicy: retentionPolicy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  NavivoxVoiceRun copyWith({
    String? sessionId,
    bool clearSessionId = false,
    String? requestId,
    bool clearRequestId = false,
    NavivoxVoiceRunStatus? status,
    NavivoxTranscriptSource? transcriptSource,
    NavivoxTtsStatus? ttsStatus,
    String? transcript,
    bool clearTranscript = false,
    Duration? duration,
    bool clearDuration = false,
    double? confidence,
    bool clearConfidence = false,
    String? reason,
    bool clearReason = false,
    String? retentionPolicy,
    DateTime? updatedAt,
  }) {
    assert(
      !clearSessionId || sessionId == null,
      'copyWith cannot set and clear sessionId at the same time.',
    );
    assert(
      !clearRequestId || requestId == null,
      'copyWith cannot set and clear requestId at the same time.',
    );
    assert(
      !clearTranscript || transcript == null,
      'copyWith cannot set and clear transcript at the same time.',
    );
    assert(
      !clearDuration || duration == null,
      'copyWith cannot set and clear duration at the same time.',
    );
    assert(
      !clearConfidence || confidence == null,
      'copyWith cannot set and clear confidence at the same time.',
    );
    assert(
      !clearReason || reason == null,
      'copyWith cannot set and clear reason at the same time.',
    );
    return NavivoxVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      sessionId: clearSessionId ? null : sessionId ?? this.sessionId,
      requestId: clearRequestId ? null : requestId ?? this.requestId,
      status: status ?? this.status,
      transcriptSource: transcriptSource ?? this.transcriptSource,
      ttsStatus: ttsStatus ?? this.ttsStatus,
      transcript: clearTranscript ? null : transcript ?? this.transcript,
      duration: clearDuration ? null : duration ?? this.duration,
      confidence: clearConfidence ? null : confidence ?? this.confidence,
      reason: clearReason ? null : reason ?? this.reason,
      retentionPolicy: retentionPolicy ?? this.retentionPolicy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
