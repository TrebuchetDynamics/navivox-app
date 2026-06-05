import '../../../../core/channel/navivox_channel.dart';
import '../../../../shared/presentation/voice_unavailable_presentation.dart';
import '../../../../shared/voice/voice_settings.dart';
import 'voice_readiness_model.dart';
import 'voice_readiness_policy.dart';

export 'voice_readiness_model.dart';

const _voiceReadinessPolicy = VoiceReadinessPolicy();

class VoiceReadinessPresentation {
  const VoiceReadinessPresentation._({
    required this.status,
    required this.blockerKind,
    required this.disabledReason,
    required this.recoveryAction,
    required this.localVoiceCaptureAvailable,
    required this.localMicrophonePermissionGranted,
    required this.canTrustServer,
  });

  factory VoiceReadinessPresentation.fromState({
    required NavivoxVoiceSettings settings,
    required NavivoxProfileContact? activeProfile,
    required bool localVoiceCaptureAvailable,
    bool localVoiceCaptureChecking = false,
    String? localVoiceCaptureUnavailableReason,
    bool? localMicrophonePermissionGranted,
    String? runtimeVoiceDisabledReason,
  }) {
    final state = _voiceReadinessPolicy.evaluate(
      settings: settings,
      activeProfile: activeProfile,
      localVoiceCaptureAvailable: localVoiceCaptureAvailable,
      localVoiceCaptureChecking: localVoiceCaptureChecking,
      localVoiceCaptureUnavailableReason: localVoiceCaptureUnavailableReason,
      localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      runtimeVoiceDisabledReason: runtimeVoiceDisabledReason,
    );
    return VoiceReadinessPresentation._(
      status: state.status,
      blockerKind: state.blockerKind,
      disabledReason: state.disabledReason,
      recoveryAction: state.recoveryAction,
      localVoiceCaptureAvailable: state.localVoiceCaptureAvailable,
      localMicrophonePermissionGranted: state.localMicrophonePermissionGranted,
      canTrustServer: state.canTrustServer,
    );
  }

  final VoiceReadinessStatus status;
  final VoiceReadinessBlockerKind? blockerKind;
  final String? disabledReason;
  final String? recoveryAction;
  final bool localVoiceCaptureAvailable;
  final bool? localMicrophonePermissionGranted;
  final bool canTrustServer;

  bool get ready => status == VoiceReadinessStatus.ready;
  bool get checking => status == VoiceReadinessStatus.checking;
  bool get blocked => status == VoiceReadinessStatus.blocked;
  bool get canStartVoiceRun => ready;

  bool get showSttDiagnostics {
    return (ready && localMicrophonePermissionGranted == false) ||
        blockerKind == VoiceReadinessBlockerKind.deviceSpeechUnavailable ||
        blockerKind == VoiceReadinessBlockerKind.microphonePermissionDenied ||
        blockerKind == VoiceReadinessBlockerKind.gatewayProfileSttUnavailable;
  }

  String get voiceSettingsSubtitle {
    return voiceSettingsSubtitleForUnavailableReason(
      blockerKind == VoiceReadinessBlockerKind.selectProfileContact
          ? selectProfileContactVoiceUnavailableReason
          : disabledReason,
    );
  }

  String get androidRecognizerStatus {
    if (checking) return 'Checking Android speech recognition.';
    return localVoiceCaptureAvailable
        ? 'Ready in Navivox; gateway STT status is separate.'
        : 'No local speech recognizer is active in Navivox.';
  }

  String get microphonePermissionStatus {
    if (blockerKind == VoiceReadinessBlockerKind.microphonePermissionDenied) {
      return 'Denied by Android. Grant microphone permission in App info.';
    }
    if (localMicrophonePermissionGranted == false) {
      return 'Not granted yet. Android may prompt when voice capture starts.';
    }
    return 'Not denied by Android in this session; checked when capture starts.';
  }

  String get gatewayProfileSttStatus {
    if (blockerKind == VoiceReadinessBlockerKind.gatewayProfileSttUnavailable) {
      return 'Gateway reported device STT unavailable for this profile.';
    }
    if (blockerKind == VoiceReadinessBlockerKind.deviceSpeechUnavailable) {
      return 'Gateway profile STT is not checked because Android speech recognition is unavailable.';
    }
    return 'Gateway profile STT is not the current blocker.';
  }
}
