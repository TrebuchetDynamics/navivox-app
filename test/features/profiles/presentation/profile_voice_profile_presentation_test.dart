import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/features/profiles/presentation/profile_voice_profile_presentation.dart';

void main() {
  const presentation = ProfileVoiceProfilePresentation();

  test('labels provider and unset voice profile values safely', () {
    const matrix = NavivoxVoiceProviderMatrix(
      sttProviders: ['local', 'whisper'],
      ttsProviders: [],
    );
    const voiceProfile = NavivoxProfileVoiceProfile(
      sttProvider: 'local',
      ttsProvider: ' ',
      voiceId: 'alloy',
      languagePolicy: 'match_user_language',
      fallbackVoice: 'text_only',
    );

    expect(
      presentation.availableSttLine(matrix),
      'Available STT: local, whisper',
    );
    expect(
      presentation.availableTtsLine(matrix),
      'Available TTS: not reported',
    );
    expect(presentation.sttProviderLine(voiceProfile), 'STT provider: local');
    expect(presentation.ttsProviderLine(voiceProfile), 'TTS provider: unset');
  });

  test('labels write-only credential status without credential refs', () {
    const status = NavivoxVoiceCredentialStatus(
      configured: true,
      required: true,
      status: 'configured',
      source: 'profile_voice_profile.stt_credential',
    );

    expect(
      presentation.sttCredentialLine(status),
      'STT credential: configured (profile_voice_profile.stt_credential)',
    );
    expect(
      presentation.ttsCredentialLine(null),
      'TTS credential: not reported',
    );
  });

  test('renders validation and redacted run-record voice evidence', () {
    const error = NavivoxVoiceProfileFieldError(
      field: 'stt_provider',
      code: 'unknown_provider',
      message: 'Unknown STT provider',
    );
    const record = NavivoxRunRecordSnapshot(
      runId: 'run-1',
      sessionId: 'session-1',
      status: 'completed',
      createdAt: null,
      updatedAt: null,
      completedAt: null,
      raw: {
        'voice': {
          'server_stt': {'provider': 'local', 'status': 'available'},
          'tts': {'provider': 'text_only', 'status': 'fallback'},
        },
      },
    );

    expect(
      presentation.validationErrorLine(error),
      'stt_provider: Unknown STT provider',
    );
    final evidence = presentation.evidenceFor(record);
    expect(evidence.serverSttLine, 'Server STT: local available');
    expect(evidence.ttsLine, 'TTS: text_only fallback');
  });
}
