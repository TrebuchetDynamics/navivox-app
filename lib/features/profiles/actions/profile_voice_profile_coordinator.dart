import '../../../core/channel/navivox_channel.dart';
import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../../../core/protocol/navivox_voice_run.dart';

final class ProfileVoiceProfileCoordinator {
  const ProfileVoiceProfileCoordinator();

  NavivoxVoiceProfileView? activeVoiceProfile({
    required NavivoxVoiceProfilesResponse? profiles,
    required NavivoxProfileContact activeProfile,
  }) {
    for (final profile
        in profiles?.profiles ?? const <NavivoxVoiceProfileView>[]) {
      if (profile.profileId == activeProfile.profileId) return profile;
    }
    return null;
  }

  ProfileVoiceEditFields beginEditing(NavivoxVoiceProfileView view) {
    final voice = view.voiceProfile;
    return ProfileVoiceEditFields(
      sttProvider: voice.sttProvider,
      ttsProvider: voice.ttsProvider,
      voiceId: voice.voiceId,
      languagePolicy: voice.languagePolicy,
      fallbackVoice: voice.fallbackVoice,
      sttCredential: '',
      ttsCredential: '',
    );
  }

  ProfileVoiceApplyRequest applyRequest({
    required String profileId,
    required String sttProvider,
    required String ttsProvider,
    required String voiceId,
    required String languagePolicy,
    required String fallbackVoice,
    required String sttCredential,
    required String ttsCredential,
  }) {
    final voiceProfile = NavivoxProfileVoiceProfile(
      sttProvider: sttProvider,
      ttsProvider: ttsProvider,
      voiceId: voiceId,
      languagePolicy: languagePolicy,
      fallbackVoice: fallbackVoice,
    );
    return ProfileVoiceApplyRequest(
      profileId: profileId,
      voiceProfile: voiceProfile,
      configSets: [
        for (final field in _voiceProfileFields(voiceProfile))
          ProfileVoiceConfigSet(
            field: 'profiles.$profileId.voice_profile.${field.name}',
            value: field.value,
          ),
      ],
      secretSets: [
        if (sttCredential.trim().isNotEmpty)
          ProfileVoiceSecretSet(
            name: 'profiles.$profileId.voice_profile.stt_credential',
            secret: sttCredential.trim(),
          ),
        if (ttsCredential.trim().isNotEmpty)
          ProfileVoiceSecretSet(
            name: 'profiles.$profileId.voice_profile.tts_credential',
            secret: ttsCredential.trim(),
          ),
      ],
    );
  }

  ProfileVoiceEffect afterValidation(
    NavivoxVoiceProfileValidationResponse validation,
  ) {
    return validation.valid
        ? const ProfileVoiceEffect.continueApply()
        : ProfileVoiceEffect.showValidation(validation);
  }

  ProfileVoiceEffect applySucceeded() {
    return const ProfileVoiceEffect.applied(
      'Voice profile sent to Gormes config admin.',
    );
  }

  ProfileVoiceEvidencePlan evidencePlan(NavivoxVoiceRun? activeRun) {
    final requestId = activeRun?.requestId?.trim();
    if (requestId != null && requestId.isNotEmpty) {
      return ProfileVoiceEvidencePlan.request(requestId);
    }
    final id = activeRun?.id.trim();
    if (id != null && id.isNotEmpty) {
      return ProfileVoiceEvidencePlan.request(id);
    }
    return const ProfileVoiceEvidencePlan.showStatus(
      'No voice run evidence yet.',
    );
  }
}

typedef _VoiceField = ({String name, String value});

List<_VoiceField> _voiceProfileFields(NavivoxProfileVoiceProfile voice) {
  return [
    (name: 'stt_provider', value: voice.sttProvider.trim()),
    (name: 'tts_provider', value: voice.ttsProvider.trim()),
    (name: 'voice_id', value: voice.voiceId.trim()),
    (name: 'language_policy', value: voice.languagePolicy.trim()),
    (name: 'fallback_voice', value: voice.fallbackVoice.trim()),
  ];
}

final class ProfileVoiceEditFields {
  const ProfileVoiceEditFields({
    required this.sttProvider,
    required this.ttsProvider,
    required this.voiceId,
    required this.languagePolicy,
    required this.fallbackVoice,
    required this.sttCredential,
    required this.ttsCredential,
  });

  final String sttProvider;
  final String ttsProvider;
  final String voiceId;
  final String languagePolicy;
  final String fallbackVoice;
  final String sttCredential;
  final String ttsCredential;
}

final class ProfileVoiceApplyRequest {
  const ProfileVoiceApplyRequest({
    required this.profileId,
    required this.voiceProfile,
    required this.configSets,
    required this.secretSets,
  });

  final String profileId;
  final NavivoxProfileVoiceProfile voiceProfile;
  final List<ProfileVoiceConfigSet> configSets;
  final List<ProfileVoiceSecretSet> secretSets;
}

final class ProfileVoiceConfigSet {
  const ProfileVoiceConfigSet({required this.field, required this.value});

  final String field;
  final String value;
}

final class ProfileVoiceSecretSet {
  const ProfileVoiceSecretSet({required this.name, required this.secret});

  final String name;
  final String secret;
}

sealed class ProfileVoiceEffect {
  const ProfileVoiceEffect._();

  const factory ProfileVoiceEffect.showValidation(
    NavivoxVoiceProfileValidationResponse validation,
  ) = ShowProfileVoiceValidationEffect;
  const factory ProfileVoiceEffect.continueApply() =
      ContinueProfileVoiceApplyEffect;
  const factory ProfileVoiceEffect.applied(String message) =
      ProfileVoiceAppliedEffect;
}

final class ShowProfileVoiceValidationEffect extends ProfileVoiceEffect {
  const ShowProfileVoiceValidationEffect(this.validation) : super._();

  final NavivoxVoiceProfileValidationResponse validation;
}

final class ContinueProfileVoiceApplyEffect extends ProfileVoiceEffect {
  const ContinueProfileVoiceApplyEffect() : super._();
}

final class ProfileVoiceAppliedEffect extends ProfileVoiceEffect {
  const ProfileVoiceAppliedEffect(this.message) : super._();

  final String message;
}

sealed class ProfileVoiceEvidencePlan {
  const ProfileVoiceEvidencePlan._();

  const factory ProfileVoiceEvidencePlan.request(String id) =
      RequestProfileVoiceEvidencePlan;
  const factory ProfileVoiceEvidencePlan.showStatus(String message) =
      ShowProfileVoiceEvidenceStatusPlan;
}

final class RequestProfileVoiceEvidencePlan extends ProfileVoiceEvidencePlan {
  const RequestProfileVoiceEvidencePlan(this.id) : super._();

  final String id;
}

final class ShowProfileVoiceEvidenceStatusPlan
    extends ProfileVoiceEvidencePlan {
  const ShowProfileVoiceEvidenceStatusPlan(this.message) : super._();

  final String message;
}
