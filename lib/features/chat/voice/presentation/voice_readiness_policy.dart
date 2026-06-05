import '../../../../core/channel/navivox_channel.dart';
import '../../../../shared/presentation/profile_health_labels.dart';
import '../../../../shared/presentation/voice_unavailable_presentation.dart';
import '../../../../shared/voice/voice_settings.dart';
import 'voice_readiness_model.dart';

final class VoiceReadinessPolicy {
  const VoiceReadinessPolicy();

  VoiceReadinessState evaluate({
    required NavivoxVoiceSettings settings,
    required NavivoxProfileContact? activeProfile,
    required bool localVoiceCaptureAvailable,
    bool localVoiceCaptureChecking = false,
    String? localVoiceCaptureUnavailableReason,
    bool? localMicrophonePermissionGranted,
    String? runtimeVoiceDisabledReason,
  }) {
    if (!settings.continuousVoiceEnabled) {
      return VoiceReadinessState.blocked(
        VoiceReadinessBlockerKind.disabledInSettings,
        'disabled in Settings',
        localVoiceCaptureAvailable: localVoiceCaptureAvailable,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }
    if (activeProfile == null) {
      return VoiceReadinessState.blocked(
        VoiceReadinessBlockerKind.selectProfileContact,
        selectProfileContactVoiceUnavailableReason,
        localVoiceCaptureAvailable: localVoiceCaptureAvailable,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }
    if (!settings.isTrusted(activeProfile.serverId)) {
      return VoiceReadinessState.blocked(
        VoiceReadinessBlockerKind.trustGateway,
        'trust ${activeProfile.serverLabel}',
        localVoiceCaptureAvailable: localVoiceCaptureAvailable,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        canTrustServer: true,
      );
    }
    if (localVoiceCaptureChecking) {
      return VoiceReadinessState.checking(
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }

    final runtimeReason = runtimeReadinessBlockerReason(
      runtimeVoiceDisabledReason,
    );
    final localReason = localCaptureReadinessBlockerReason(
      localVoiceCaptureUnavailableReason,
    );
    final localBlockerReason = runtimeReason ?? localReason;
    if (!localVoiceCaptureAvailable || localBlockerReason != null) {
      final reason = localBlockerReason ?? deviceSttUnavailableReason;
      return VoiceReadinessState.blocked(
        deviceBlockerKind(reason),
        reason,
        localVoiceCaptureAvailable: false,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        recoveryAction: deviceRecoveryAction(activeProfile, reason),
      );
    }

    final profileVoiceReason = canonicalVoiceUnavailableReason(
      activeProfile.voiceCapability.captureUnavailableReason,
      emptyAsNull: true,
    );
    if (profileVoiceReason != null) {
      return VoiceReadinessState.blocked(
        VoiceReadinessBlockerKind.gatewayProfileSttUnavailable,
        profileVoiceReason,
        localVoiceCaptureAvailable: true,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        recoveryAction: profileRecoveryAction(
          activeProfile,
          profileVoiceReason,
        ),
      );
    }
    if (activeProfile.health != NavivoxProfileHealth.online) {
      return VoiceReadinessState.blocked(
        VoiceReadinessBlockerKind.profileContactNotOnline,
        profileHealthLabel(activeProfile.health),
        localVoiceCaptureAvailable: true,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }
    if (!activeProfile.micAvailable) {
      return VoiceReadinessState.blocked(
        VoiceReadinessBlockerKind.profileMicUnavailable,
        'mic unavailable',
        localVoiceCaptureAvailable: true,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      );
    }

    return VoiceReadinessState.ready(
      localMicrophonePermissionGranted: localMicrophonePermissionGranted,
    );
  }

  String? runtimeReadinessBlockerReason(String? reason) {
    final canonical = canonicalVoiceUnavailableReason(
      reason,
      emptyAsNull: true,
    );
    return switch (canonical) {
      deviceSttUnavailableReason ||
      microphonePermissionDeniedReason => canonical,
      _ => null,
    };
  }

  String? localCaptureReadinessBlockerReason(String? reason) {
    return canonicalVoiceUnavailableReason(reason, emptyAsNull: true);
  }

  VoiceReadinessBlockerKind deviceBlockerKind(String reason) {
    return reason == microphonePermissionDeniedReason
        ? VoiceReadinessBlockerKind.microphonePermissionDenied
        : VoiceReadinessBlockerKind.deviceSpeechUnavailable;
  }

  String? deviceRecoveryAction(NavivoxProfileContact profile, String reason) {
    final recoveryAction = profile.voiceCapability.recoveryAction.trim();
    if (reason == deviceSttUnavailableReason && recoveryAction.isNotEmpty) {
      return recoveryAction;
    }
    return defaultVoiceUnavailableRecoveryAction(reason);
  }

  String? profileRecoveryAction(NavivoxProfileContact profile, String reason) {
    final recoveryAction = profile.voiceCapability.recoveryAction.trim();
    if (recoveryAction.isNotEmpty) return recoveryAction;
    return defaultVoiceUnavailableRecoveryAction(reason);
  }
}

final class VoiceReadinessState {
  const VoiceReadinessState._({
    required this.status,
    required this.blockerKind,
    required this.disabledReason,
    required this.recoveryAction,
    required this.localVoiceCaptureAvailable,
    required this.localMicrophonePermissionGranted,
    required this.canTrustServer,
  });

  const VoiceReadinessState.ready({bool? localMicrophonePermissionGranted})
    : this._(
        status: VoiceReadinessStatus.ready,
        blockerKind: null,
        disabledReason: null,
        recoveryAction: null,
        localVoiceCaptureAvailable: true,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        canTrustServer: false,
      );

  const VoiceReadinessState.checking({bool? localMicrophonePermissionGranted})
    : this._(
        status: VoiceReadinessStatus.checking,
        blockerKind: null,
        disabledReason: null,
        recoveryAction: null,
        localVoiceCaptureAvailable: false,
        localMicrophonePermissionGranted: localMicrophonePermissionGranted,
        canTrustServer: false,
      );

  const VoiceReadinessState.blocked(
    VoiceReadinessBlockerKind blockerKind,
    String disabledReason, {
    required bool localVoiceCaptureAvailable,
    bool? localMicrophonePermissionGranted,
    String? recoveryAction,
    bool canTrustServer = false,
  }) : this._(
         status: VoiceReadinessStatus.blocked,
         blockerKind: blockerKind,
         disabledReason: disabledReason,
         recoveryAction: recoveryAction,
         localVoiceCaptureAvailable: localVoiceCaptureAvailable,
         localMicrophonePermissionGranted: localMicrophonePermissionGranted,
         canTrustServer: canTrustServer,
       );

  final VoiceReadinessStatus status;
  final VoiceReadinessBlockerKind? blockerKind;
  final String? disabledReason;
  final String? recoveryAction;
  final bool localVoiceCaptureAvailable;
  final bool? localMicrophonePermissionGranted;
  final bool canTrustServer;
}
