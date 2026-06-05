import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/chat/voice/presentation/voice_readiness_model.dart';
import 'package:navivox/features/chat/voice/presentation/voice_readiness_policy.dart';
import 'package:navivox/shared/voice/voice_settings.dart';

import '../../../shared/fixtures/profile_contact_fixtures.dart';
import '../../shared/profiles/profile_scope_test_contracts.dart';
import '../../shared/voice/voice_recovery_test_fixtures.dart';
import '../../shared/voice/voice_settings_test_fixtures.dart';

void main() {
  const policy = VoiceReadinessPolicy();
  final profile = mineruBuilderProfile(
    displayName: 'Mineru',
    latestPreview: 'Ready',
    workspaceRootCount: 0,
  );
  final trusted = trustedVoiceSettingsForScope(chatMineruProfileScope);

  test('prioritizes settings, profile selection, and trust before device', () {
    final disabled = policy.evaluate(
      settings: const NavivoxVoiceSettings(
        continuousVoiceEnabled: false,
        trustedServerIds: {'local'},
      ),
      activeProfile: profile,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureUnavailableReason: deviceSttUnavailableReason,
    );
    final noProfile = policy.evaluate(
      settings: trusted,
      activeProfile: null,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureUnavailableReason: deviceSttUnavailableReason,
    );
    final untrusted = policy.evaluate(
      settings: untrustedVoiceSettings,
      activeProfile: profile,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureUnavailableReason: deviceSttUnavailableReason,
    );

    expect(disabled.blockerKind, VoiceReadinessBlockerKind.disabledInSettings);
    expect(
      noProfile.blockerKind,
      VoiceReadinessBlockerKind.selectProfileContact,
    );
    expect(untrusted.blockerKind, VoiceReadinessBlockerKind.trustGateway);
    expect(untrusted.canTrustServer, isTrue);
  });

  test('treats checking and pre-capture mic state as non-failure states', () {
    final checking = policy.evaluate(
      settings: trusted,
      activeProfile: profile,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureChecking: true,
    );
    final promptLater = policy.evaluate(
      settings: trusted,
      activeProfile: profile,
      localVoiceCaptureAvailable: true,
      localMicrophonePermissionGranted: false,
    );

    expect(checking.status, VoiceReadinessStatus.checking);
    expect(checking.disabledReason, isNull);
    expect(promptLater.status, VoiceReadinessStatus.ready);
    expect(promptLater.localMicrophonePermissionGranted, isFalse);
  });

  test(
    'permanent runtime failures block readiness but transient ones do not',
    () {
      final denied = policy.evaluate(
        settings: trusted,
        activeProfile: profile,
        localVoiceCaptureAvailable: true,
        runtimeVoiceDisabledReason: microphonePermissionDeniedReason,
      );
      final noSpeech = policy.evaluate(
        settings: trusted,
        activeProfile: profile,
        localVoiceCaptureAvailable: true,
        runtimeVoiceDisabledReason: 'no speech detected',
      );

      expect(
        denied.blockerKind,
        VoiceReadinessBlockerKind.microphonePermissionDenied,
      );
      expect(denied.disabledReason, microphonePermissionDeniedReason);
      expect(noSpeech.status, VoiceReadinessStatus.ready);
    },
  );

  test('orders device, gateway STT, health, and profile mic blockers', () {
    final device = policy.evaluate(
      settings: trusted,
      activeProfile: profile,
      localVoiceCaptureAvailable: false,
      localVoiceCaptureUnavailableReason: deviceSttUnavailableReason,
    );
    final gateway = policy.evaluate(
      settings: trusted,
      activeProfile: mineruBuilderProfile(
        latestPreview: 'Ready',
        voiceCapability: const NavivoxVoiceCapability(
          disabledReason: deviceSttUnavailableReason,
          recoveryAction: 'Enable profile STT',
        ),
      ),
      localVoiceCaptureAvailable: true,
    );
    final offline = policy.evaluate(
      settings: trusted,
      activeProfile: mineruBuilderProfile(
        latestPreview: 'Offline',
        health: NavivoxProfileHealth.offline,
      ),
      localVoiceCaptureAvailable: true,
    );
    final noMic = policy.evaluate(
      settings: trusted,
      activeProfile: mineruBuilderProfile(
        latestPreview: 'Ready',
        micAvailable: false,
      ),
      localVoiceCaptureAvailable: true,
    );

    expect(
      device.blockerKind,
      VoiceReadinessBlockerKind.deviceSpeechUnavailable,
    );
    expect(
      gateway.blockerKind,
      VoiceReadinessBlockerKind.gatewayProfileSttUnavailable,
    );
    expect(gateway.recoveryAction, 'Enable profile STT');
    expect(
      offline.blockerKind,
      VoiceReadinessBlockerKind.profileContactNotOnline,
    );
    expect(noMic.blockerKind, VoiceReadinessBlockerKind.profileMicUnavailable);
  });
}
