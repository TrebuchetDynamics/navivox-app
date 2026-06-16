import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

import '../../../support/test_navivox_channel.dart';

void main() {
  test('channel state exposes voice runs in insertion order', () {
    final first = NavivoxVoiceRun.recording(
      id: 'voice-1',
      serverId: 'local',
      profileId: 'mineru',
      createdAt: DateTime.utc(2026, 5, 21, 12),
    );
    final second = NavivoxVoiceRun.recording(
      id: 'voice-2',
      serverId: 'local',
      profileId: 'support',
      createdAt: DateTime.utc(2026, 5, 21, 12, 1),
    );

    final state = NavivoxChannelState(
      voiceRuns: {first.id: first, second.id: second},
    );

    expect(state.voiceRunsList.map((run) => run.id), ['voice-1', 'voice-2']);
    // With no tracked active id there is no in-flight run, but the most recent
    // run is still resolvable for history/evidence.
    expect(state.activeVoiceRun, isNull);
    expect(state.latestVoiceRun?.id, 'voice-2');
  });

  test('test channel can create stage cancel fail and submit voice runs', () {
    final channel = TestNavivoxChannel()
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
          micAvailable: true,
        ),
      ], selectedKey: 'local::mineru');

    final id = channel.startVoiceRun();
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.recording,
    );

    channel.stageVoiceRunTranscript(
      voiceRunId: id,
      transcript: 'check status',
      duration: const Duration(milliseconds: 900),
      confidence: 0.9,
    );
    expect(
      channel.state.voiceRuns[id]?.status,
      NavivoxVoiceRunStatus.pendingSend,
    );

    channel.submitVoiceRun(id);
    expect(channel.sentVoiceTranscripts, ['check status']);
    expect(
      channel.state.voiceRuns[id]?.status,
      NavivoxVoiceRunStatus.submitted,
    );
  });

  test('active voice run clears when the run is cancelled', () {
    final channel = TestNavivoxChannel();
    final id = channel.startVoiceRun();
    expect(channel.state.activeVoiceRun?.id, id);

    channel.cancelVoiceRun(id);

    expect(
      channel.state.activeVoiceRun,
      isNull,
      reason: 'a terminal run is not in flight',
    );
    expect(channel.state.latestVoiceRun?.id, id);
    expect(
      channel.state.latestVoiceRun?.status,
      NavivoxVoiceRunStatus.cancelled,
    );
  });

  test('active voice run clears when the run fails', () {
    final channel = TestNavivoxChannel();
    final id = channel.startVoiceRun();

    channel.failVoiceRun(id, reason: 'mic unavailable');

    expect(channel.state.activeVoiceRun, isNull);
    expect(channel.state.latestVoiceRun?.status, NavivoxVoiceRunStatus.failed);
  });

  test('submitted run remains the active in-flight run', () {
    final channel = TestNavivoxChannel();
    final id = channel.startVoiceRun();
    channel.stageVoiceRunTranscript(
      voiceRunId: id,
      transcript: 'still going',
      duration: const Duration(milliseconds: 500),
      confidence: 0.8,
    );

    channel.submitVoiceRun(id);

    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.submitted,
      reason: 'submitted is awaiting the server, still in flight',
    );
  });
}
