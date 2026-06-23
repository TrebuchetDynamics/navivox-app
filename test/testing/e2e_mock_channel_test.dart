import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';
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

  test('E2E mock async feature methods return safe fixtures', () async {
    final channel = E2EMockChannel();
    await channel.connect(baseUrl: 'http://127.0.0.1:8765');

    final seed = await channel.profileSeed(seed: 'work on mineru');
    final applied = await channel.profileSeed(
      seed: 'work on mineru',
      apply: true,
    );
    final voiceProfiles = await channel.voiceProfiles();
    final validation = await channel.validateVoiceProfile(
      profileId: 'mineru',
      voiceProfile: const NavivoxProfileVoiceProfile(sttProvider: 'device'),
    );
    final record = await channel.runRecord('run-1');
    final overview = await channel.memoryOverview();
    final search = await channel.memorySearch(query: 'hello');
    final detail = await channel.memoryDetail(
      id: 'memory-1',
      type: NavivoxMemoryType.observations,
    );
    final action = await channel.memoryAction(
      id: 'memory-1',
      type: NavivoxMemoryType.observations,
      action: NavivoxMemoryActionType.pin,
    );
    final diff = await channel.diffConfigAdmin(const []);
    final validated = await channel.validateConfigAdmin(const []);
    final configApplied = await channel.applyConfigAdmin(const []);

    expect(seed.isDraft, isTrue);
    expect(applied.isApplied, isTrue);
    expect(voiceProfiles.action, 'voice_profiles.get');
    expect(validation.valid, isTrue);
    expect(record.runId, 'run-1');
    expect(overview.profileId, isNotEmpty);
    expect(search.items, isEmpty);
    expect(detail.id, 'memory-1');
    expect(action.accepted, isTrue);
    expect(diff.action, 'config.diff');
    expect(validated.action, 'config.validate');
    expect(configApplied.applied, isTrue);
  });
}
