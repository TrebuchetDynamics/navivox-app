import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/features/profiles/actions/profile_voice_profile_coordinator.dart';

void main() {
  const coordinator = ProfileVoiceProfileCoordinator();
  const contact = NavivoxProfileContact(
    serverId: 'local',
    profileId: 'mineru',
    displayName: 'Mineru Builder',
    serverLabel: 'Local Gormes',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
  );

  test('selects active profile voice view by profile id', () {
    final response = NavivoxVoiceProfilesResponse(
      action: 'voice_profiles.get',
      providerMatrix: const NavivoxVoiceProviderMatrix(),
      profiles: [
        _view(profileId: 'support', ttsProvider: 'piper'),
        _view(profileId: 'mineru', ttsProvider: 'openai'),
      ],
    );

    final active = coordinator.activeVoiceProfile(
      profiles: response,
      activeProfile: contact,
    );

    expect(active?.profileId, 'mineru');
    expect(active?.voiceProfile.ttsProvider, 'openai');
  });

  test('builds edit fields and clears write-only credential inputs', () {
    final fields = coordinator.beginEditing(_view(profileId: 'mineru'));

    expect(fields.sttProvider, 'local');
    expect(fields.ttsProvider, 'openai');
    expect(fields.voiceId, 'alloy');
    expect(fields.languagePolicy, 'match_user_language');
    expect(fields.fallbackVoice, 'text_only');
    expect(fields.sttCredential, isEmpty);
    expect(fields.ttsCredential, isEmpty);
  });

  test(
    'apply request trims config fields and includes only nonblank secrets',
    () {
      final request = coordinator.applyRequest(
        profileId: 'mineru',
        sttProvider: ' local ',
        ttsProvider: ' piper ',
        voiceId: ' amy ',
        languagePolicy: ' match_user_language ',
        fallbackVoice: ' text_only ',
        sttCredential: ' __secret__ ',
        ttsCredential: '   ',
      );

      expect(request.voiceProfile.sttProvider, ' local ');
      expect(
        request.configSets.map((set) => (field: set.field, value: set.value)),
        contains((
          field: 'profiles.mineru.voice_profile.tts_provider',
          value: 'piper',
        )),
      );
      expect(request.secretSets, hasLength(1));
      expect(
        request.secretSets.single.name,
        'profiles.mineru.voice_profile.stt_credential',
      );
      expect(request.secretSets.single.secret, '__secret__');
    },
  );

  test('validation and apply outcomes map to typed effects', () {
    expect(
      coordinator.afterValidation(_validation(valid: false)),
      isA<ShowProfileVoiceValidationEffect>(),
    );
    expect(
      coordinator.afterValidation(_validation(valid: true)),
      isA<ContinueProfileVoiceApplyEffect>(),
    );
    final applied = coordinator.applySucceeded();
    expect(applied, isA<ProfileVoiceAppliedEffect>());
    expect(
      (applied as ProfileVoiceAppliedEffect).message,
      'Voice profile sent to Gormes config admin.',
    );
  });

  test('evidence plan prefers gateway request id over local voice run id', () {
    final run = NavivoxVoiceRun.recording(
      id: 'voice-1',
      serverId: 'local',
      profileId: 'mineru',
      createdAt: DateTime.utc(2026),
    ).markSubmitted(requestId: 'req-1');

    final plan = coordinator.evidencePlan(run);

    expect(plan, isA<RequestProfileVoiceEvidencePlan>());
    expect((plan as RequestProfileVoiceEvidencePlan).id, 'req-1');
  });

  test('evidence plan reports no evidence when no run id exists', () {
    final plan = coordinator.evidencePlan(null);

    expect(plan, isA<ShowProfileVoiceEvidenceStatusPlan>());
    expect(
      (plan as ShowProfileVoiceEvidenceStatusPlan).message,
      'No voice run evidence yet.',
    );
  });
}

NavivoxVoiceProfileView _view({
  required String profileId,
  String ttsProvider = 'openai',
}) {
  return NavivoxVoiceProfileView(
    profileId: profileId,
    displayName: profileId,
    voiceProfile: NavivoxProfileVoiceProfile(
      sttProvider: 'local',
      ttsProvider: ttsProvider,
      voiceId: 'alloy',
      languagePolicy: 'match_user_language',
      fallbackVoice: 'text_only',
    ),
    valid: true,
  );
}

NavivoxVoiceProfileValidationResponse _validation({required bool valid}) {
  return NavivoxVoiceProfileValidationResponse(
    action: 'voice_profiles.validate',
    providerMatrix: const NavivoxVoiceProviderMatrix(),
    valid: valid,
    errors: valid
        ? const []
        : const [
            NavivoxVoiceProfileFieldError(
              field: 'stt_provider',
              code: 'unknown_provider',
              message: 'Unknown STT provider',
            ),
          ],
  );
}
