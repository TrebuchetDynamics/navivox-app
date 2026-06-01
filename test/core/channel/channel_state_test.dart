import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';

void main() {
  test('copyWith can clear nullable selection and config fields', () {
    const state = NavivoxChannelState(
      activeServerId: 'local',
      activeVoiceRunId: 'voice-1',
      selectedAgentId: 'agent-1',
      selectedProfileContactKey: 'local::mineru',
      configSchema: {'fields': []},
      configDiff: {'changes': []},
    );

    final cleared = state.copyWith(
      clearActiveServerId: true,
      clearActiveVoiceRunId: true,
      clearSelectedAgentId: true,
      clearSelectedProfileContactKey: true,
      clearConfigSchema: true,
      clearConfigDiff: true,
    );

    expect(cleared.activeServerId, isNull);
    expect(cleared.activeVoiceRunId, isNull);
    expect(cleared.selectedAgentId, isNull);
    expect(cleared.selectedProfileContactKey, isNull);
    expect(cleared.configSchema, isNull);
    expect(cleared.configDiff, isNull);
  });
}
