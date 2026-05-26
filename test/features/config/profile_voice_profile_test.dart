import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/features/config/screens/config_screen.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  testWidgets('renders and applies profile voice settings through Gormes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final channel = _seedChannel()
      ..seedVoiceProfiles(_voiceProfiles())
      ..seedVoiceProfileValidation(_validValidation())
      ..seedRunRecord(_voiceFallbackRecord());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ConfigScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(channel.voiceProfileRequests, 1);
    expect(find.text('Voice profile'), findsOneWidget);
    expect(find.text('STT provider: local'), findsOneWidget);
    expect(find.text('TTS provider: openai'), findsOneWidget);
    expect(find.text('Voice ID: alloy'), findsOneWidget);
    expect(
      find.text(
        'STT credential: configured (profile_voice_profile.stt_credential)',
      ),
      findsOneWidget,
    );
    expect(find.text('TTS credential: missing'), findsOneWidget);
    expect(find.textContaining('private-stt-ref'), findsNothing);
    expect(find.textContaining('private-tts-ref'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('voice-profile-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('voice-profile-input-tts_provider')),
      'piper',
    );
    await tester.enterText(
      find.byKey(const ValueKey('voice-profile-input-voice_id')),
      'amy',
    );
    await tester.enterText(
      find.byKey(const ValueKey('voice-profile-input-stt_credential')),
      '__write_only_stt_test_value__',
    );
    await tester.tap(
      find.byKey(const ValueKey('voice-profile-validate-apply')),
    );
    await tester.pumpAndSettle();

    expect(channel.voiceProfileValidateCalls.single.profileId, 'mineru');
    expect(
      channel.voiceProfileValidateCalls.single.voiceProfile.ttsProvider,
      'piper',
    );
    expect(
      channel.configSetCalls,
      contains((
        field: 'profiles.mineru.voice_profile.tts_provider',
        value: 'piper',
      )),
    );
    expect(
      channel.configSetCalls,
      contains((field: 'profiles.mineru.voice_profile.voice_id', value: 'amy')),
    );
    expect(
      channel.configSecretSetCalls.single.name,
      'profiles.mineru.voice_profile.stt_credential',
    );
    expect(find.textContaining('__write_only_stt_test_value__'), findsNothing);
    expect(
      find.text('Voice profile sent to Gormes config admin.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('voice-profile-load-evidence')));
    await tester.pumpAndSettle();

    expect(channel.runRecordCalls.single, 'req-profile-voice');
    expect(find.text('Server STT: local available'), findsOneWidget);
    expect(find.text('TTS: text_only fallback'), findsOneWidget);
  });

  testWidgets('invalid voice providers do not dispatch config writes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final channel = _seedChannel()
      ..seedVoiceProfiles(_voiceProfiles())
      ..seedVoiceProfileValidation(_invalidValidation());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ConfigScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Text chat remains available when voice providers are unavailable.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('voice-profile-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('voice-profile-input-stt_provider')),
      'bogus',
    );
    await tester.tap(
      find.byKey(const ValueKey('voice-profile-validate-apply')),
    );
    await tester.pumpAndSettle();

    expect(
      channel.voiceProfileValidateCalls.single.voiceProfile.sttProvider,
      'bogus',
    );
    expect(channel.configSetCalls, isEmpty);
    expect(channel.configSecretSetCalls, isEmpty);
    expect(find.text('stt_provider: Unknown STT provider'), findsOneWidget);
  });
}

TestNavivoxChannel _seedChannel() {
  return TestNavivoxChannel()
    ..seedServers(const [
      NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
    ], activeServerId: 'local')
    ..seedProfileContacts(const [
      NavivoxProfileContact(
        serverId: 'local',
        profileId: 'mineru',
        displayName: 'Mineru Builder',
        serverLabel: 'local',
        health: NavivoxProfileHealth.online,
        latestPreview: 'Ready',
        micAvailable: true,
      ),
    ], selectedKey: 'local::mineru')
    ..seedVoiceRuns([
      NavivoxVoiceRun.recording(
        id: 'voice-1',
        serverId: 'local',
        profileId: 'mineru',
        createdAt: DateTime.utc(2026, 5, 24, 10),
      ).markSubmitted(requestId: 'req-profile-voice'),
    ]);
}

NavivoxVoiceProfilesResponse _voiceProfiles() {
  return const NavivoxVoiceProfilesResponse(
    action: 'voice_profiles.get',
    providerMatrix: NavivoxVoiceProviderMatrix(
      sttProviders: ['local', 'whisper'],
      ttsProviders: ['openai', 'piper'],
    ),
    profiles: [
      NavivoxVoiceProfileView(
        profileId: 'mineru',
        displayName: 'Mineru Builder',
        voiceProfile: NavivoxProfileVoiceProfile(
          sttProvider: 'local',
          ttsProvider: 'openai',
          voiceId: 'alloy',
          languagePolicy: 'match_user_language',
          fallbackVoice: 'text_only',
        ),
        credentialStatusRefs: {
          'stt': NavivoxVoiceCredentialStatus(
            configured: true,
            required: true,
            status: 'configured',
            source: 'profile_voice_profile.stt_credential',
          ),
          'tts': NavivoxVoiceCredentialStatus(
            configured: false,
            required: true,
            status: 'missing',
          ),
        },
        valid: true,
      ),
    ],
  );
}

NavivoxVoiceProfileValidationResponse _validValidation() {
  return const NavivoxVoiceProfileValidationResponse(
    action: 'voice_profiles.validate',
    providerMatrix: NavivoxVoiceProviderMatrix(
      sttProviders: ['local', 'whisper'],
      ttsProviders: ['openai', 'piper'],
    ),
    valid: true,
    validation: NavivoxVoiceProfileValidation(
      profileId: 'mineru',
      voiceProfile: NavivoxProfileVoiceProfile(
        sttProvider: 'local',
        ttsProvider: 'piper',
        voiceId: 'amy',
        languagePolicy: 'match_user_language',
        fallbackVoice: 'text_only',
      ),
      valid: true,
    ),
  );
}

NavivoxVoiceProfileValidationResponse _invalidValidation() {
  return const NavivoxVoiceProfileValidationResponse(
    action: 'voice_profiles.validate',
    providerMatrix: NavivoxVoiceProviderMatrix(
      sttProviders: ['local'],
      ttsProviders: ['piper'],
    ),
    valid: false,
    errors: [
      NavivoxVoiceProfileFieldError(
        field: 'stt_provider',
        code: 'unknown_provider',
        message: 'Unknown STT provider',
      ),
    ],
  );
}

NavivoxRunRecordSnapshot _voiceFallbackRecord() {
  return const NavivoxRunRecordSnapshot(
    runId: 'req-profile-voice',
    sessionId: 's-profile-voice',
    status: 'completed',
    createdAt: null,
    updatedAt: null,
    completedAt: null,
    raw: {
      'voice': {
        'server_stt': {'provider': 'local', 'status': 'available'},
        'tts': {
          'provider': 'text_only',
          'voice_id': 'text_only',
          'status': 'fallback',
        },
      },
    },
  );
}
