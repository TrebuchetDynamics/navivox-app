import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/protocol/voice/models/navivox_voice_run.dart';
import '../../../core/protocol/voice_unavailable_reason.dart';
import '../../../shared/voice/voice_capture_failures.dart';
import '../../../shared/voice/voice_capture_service.dart';

class HermesVoiceRunFailureResult {
  const HermesVoiceRunFailureResult({
    required this.reason,
    this.runtimeVoiceDisabledReason,
  });

  final String reason;
  final String? runtimeVoiceDisabledReason;
}

class HermesVoiceRunCaptureResult {
  const HermesVoiceRunCaptureResult({
    required this.handledLocalCommand,
    this.scheduleAutoSendFor,
  });

  final bool handledLocalCommand;
  final String? scheduleAutoSendFor;
}

class HermesVoiceRunAutoSendResult {
  const HermesVoiceRunAutoSendResult({required this.submitted});

  final bool submitted;
}

class HermesVoiceRunCancelResult {
  const HermesVoiceRunCancelResult({this.cancelledVoiceRunId});

  final String? cancelledVoiceRunId;
}

/// Drives the continuous/push-to-talk voice-capture-to-Hermes-text-turn
/// lifecycle. Same shape as `VoiceRunController` (Gormes/`NavivoxChannel`),
/// but typed against the native `HermesChannel` per
/// docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md.
class HermesVoiceRunController {
  String? pendingVoiceRunId;
  String? runtimeVoiceDisabledReason;
  String? notice;

  void clearRuntimeVoiceDisabledReason() {
    runtimeVoiceDisabledReason = null;
  }

  String startCapture(HermesChannel channel) {
    pendingVoiceRunId = channel.startVoiceRun();
    return pendingVoiceRunId!;
  }

  HermesVoiceRunFailureResult captureFailed(
    HermesChannel channel,
    Object error,
  ) {
    final reason = _failureReason(error);
    final id = pendingVoiceRunId;
    if (id != null) {
      channel.failVoiceRun(id, reason: reason);
    }
    pendingVoiceRunId = null;
    final runtimeReason = error is DeviceSpeechUnavailable ? reason : null;
    if (runtimeReason != null) {
      runtimeVoiceDisabledReason = runtimeReason;
    }
    return HermesVoiceRunFailureResult(
      reason: reason,
      runtimeVoiceDisabledReason: runtimeReason,
    );
  }

  HermesVoiceRunCaptureResult captureSucceeded(
    HermesChannel channel,
    VoiceCapture capture, {
    required bool Function(String transcript) handleLocalCommand,
  }) {
    if (handleLocalCommand(capture.transcript)) {
      final id = pendingVoiceRunId;
      if (id != null) {
        channel.cancelVoiceRun(id, reason: 'local voice command');
        pendingVoiceRunId = null;
      }
      return const HermesVoiceRunCaptureResult(handledLocalCommand: true);
    }

    final voiceRunId = pendingVoiceRunId ?? channel.startVoiceRun();
    pendingVoiceRunId = voiceRunId;
    channel.stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: capture.transcript,
      duration: capture.duration,
      confidence: capture.confidence,
    );
    notice = 'Sending...';
    return HermesVoiceRunCaptureResult(
      handledLocalCommand: false,
      scheduleAutoSendFor: voiceRunId,
    );
  }

  HermesVoiceRunAutoSendResult autoSendIfPending(
    HermesChannel channel,
    String voiceRunId,
  ) {
    if (pendingVoiceRunId != voiceRunId) {
      return const HermesVoiceRunAutoSendResult(submitted: false);
    }
    final run = channel.state.voiceRuns[voiceRunId];
    if (run?.status != NavivoxVoiceRunStatus.pendingSend) {
      return const HermesVoiceRunAutoSendResult(submitted: false);
    }
    pendingVoiceRunId = null;
    notice = null;
    channel.submitVoiceRun(voiceRunId);
    return const HermesVoiceRunAutoSendResult(submitted: true);
  }

  HermesVoiceRunCancelResult cancelPending(HermesChannel? channel) {
    final voiceRunId = pendingVoiceRunId ?? channel?.state.activeVoiceRun?.id;
    if (channel != null && voiceRunId != null) {
      channel.cancelVoiceRun(voiceRunId);
    }
    pendingVoiceRunId = null;
    notice = 'Voice turn cancelled before server commit.';
    return HermesVoiceRunCancelResult(cancelledVoiceRunId: voiceRunId);
  }

  String _failureReason(Object error) {
    if (error is VoiceCaptureTimeout) return 'Voice capture timed out.';
    if (error is DeviceSpeechUnavailable) {
      return canonicalVoiceUnavailableReason(
            error.message,
            emptyAsNull: true,
          ) ??
          deviceSttUnavailableReason;
    }
    if (error is SpeechToTextCaptureFailure && error.isNoTranscript) {
      return noSpeechDetectedVoiceCaptureMessage;
    }
    return 'Voice capture failed.';
  }
}
