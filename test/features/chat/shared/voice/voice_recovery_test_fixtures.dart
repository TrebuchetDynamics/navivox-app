import 'package:navivox/shared/presentation/voice_unavailable_presentation.dart'
    as voice_unavailable_policy;

/// Shared voice recovery reason and copy fixtures used by chat presentation and control tests.
const deviceSttUnavailableReason =
    voice_unavailable_policy.deviceSttUnavailableReason;
const rawDeviceSttUnavailableReason = ' Device STT unavailable ';
const microphonePermissionDeniedReason =
    voice_unavailable_policy.microphonePermissionDeniedReason;

const deviceSttRecoveryAction = 'Enable device speech recognition';
const androidSpeechRecognitionRecoveryAction =
    'Enable Android speech recognition';
final deviceSttRecoveryCopy = voice_unavailable_policy
    .defaultVoiceUnavailableRecoveryAction(deviceSttUnavailableReason)!;
final microphonePermissionRecoveryCopy = voice_unavailable_policy
    .defaultVoiceUnavailableRecoveryAction(microphonePermissionDeniedReason)!;
final deviceSttSettingsReviewCopy = voice_unavailable_policy
    .voiceSettingsSubtitleForUnavailableReason(deviceSttUnavailableReason);
final microphonePermissionSettingsReviewCopy = voice_unavailable_policy
    .voiceSettingsSubtitleForUnavailableReason(
      microphonePermissionDeniedReason,
    );
const gatewayProfileSttBlockedByDeviceCopy =
    'Gateway profile STT is not checked because Android speech recognition is unavailable.';
const gatewayProfileSttUnavailableCopy =
    'Gateway reported device STT unavailable for this profile.';
