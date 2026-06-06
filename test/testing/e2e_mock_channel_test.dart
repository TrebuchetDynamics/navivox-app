import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/testing/e2e_mock_channel.dart';

void main() {
  test('E2E mock disconnect clears gateway state', () async {
    final channel = E2EMockChannel();
    await channel.connect(baseUrl: 'http://127.0.0.1:8765');

    expect(channel.state.hasServers, isTrue);
    expect(channel.state.profileContacts, isNotEmpty);

    await channel.disconnect();

    expect(channel.state.hasServers, isFalse);
    expect(channel.state.profileContacts, isEmpty);
    expect(channel.state.selectedProfileContactKey, isNull);
  });

  test(
    'E2E mock voice runs use unique ids and create transcript messages',
    () async {
      final channel = E2EMockChannel();
      await channel.connect(baseUrl: 'http://127.0.0.1:8765');

      final first = channel.startVoiceRun();
      final second = channel.startVoiceRun();

      expect(first, isNot(second));
      expect(channel.state.voiceRuns, contains(first));
      expect(channel.state.voiceRuns, contains(second));

      channel.stageVoiceRunTranscript(
        voiceRunId: second,
        transcript: 'hello by voice',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      );
      expect(
        channel.state.voiceRuns[second]?.status,
        NavivoxVoiceRunStatus.pendingSend,
      );

      channel.submitVoiceRun(second);

      expect(
        channel.state.voiceRuns[second]?.status,
        NavivoxVoiceRunStatus.submitted,
      );
      expect(
        channel.state.messagesList.where(
          (message) => message.voice?.voiceRunId == second,
        ),
        hasLength(1),
      );
      expect(channel.state.messagesList.last.text, 'Echo: hello by voice');
    },
  );
}
