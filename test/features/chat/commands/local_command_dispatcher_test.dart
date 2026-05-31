import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/features/chat/commands/local_command_dispatcher.dart';
import 'package:navivox/features/chat/commands/local_command_intent.dart';
import 'package:navivox/router/app_routes.dart';

import '../shared/profiles/profile_contact_chat_test_fixtures.dart';
import '../shared/profiles/profile_scope_test_helpers.dart';

void main() {
  const dispatcher = LocalCommandDispatcher();

  test('returns not consumed for no-op intents', () {
    final channel = mineruReadyProfileChannel();

    final result = dispatcher.dispatch(
      channel,
      const LocalCommandIntent.none(),
    );

    expect(result.consumed, isFalse);
    expect(result.enterCommandMode, isFalse);
    expect(result.cancelPendingVoice, isFalse);
    expect(result.routeLocation, isNull);
    expect(result.message, isNull);
  });

  test('requests command mode without mutating channel state', () {
    final channel = mineruReadyProfileChannel();

    final result = dispatcher.dispatch(
      channel,
      const LocalCommandIntent.enterCommandMode(),
    );

    expect(result.consumed, isTrue);
    expect(result.enterCommandMode, isTrue);
    expect(channel.cancelRequests, 0);
    expect(channel.stopRequests, 0);
    expect(channel.selectedProfileScope, isNull);
  });

  test('cancel command requests pending Voice run cancellation first', () {
    final channel = mineruReadyProfileChannel();
    final voiceRunId = channel.startVoiceRun();
    channel.stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: 'before commit',
      duration: const Duration(milliseconds: 500),
      confidence: 0.95,
    );

    final result = dispatcher.dispatch(
      channel,
      const LocalCommandIntent.cancel(),
    );

    expect(result.consumed, isTrue);
    expect(result.cancelPendingVoice, isTrue);
    expect(result.message, isNull);
    expect(channel.cancelRequests, 0);
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.pendingSend,
    );
  });

  test('cancel and stop commands dispatch active Gormes turn actions', () {
    final channel = mineruReadyProfileChannel();

    final cancel = dispatcher.dispatch(
      channel,
      const LocalCommandIntent.cancel(),
    );
    final stop = dispatcher.dispatch(channel, const LocalCommandIntent.stop());

    expect(
      cancel.message,
      'Cancel requested. Started side effects may still exist.',
    );
    expect(
      stop.message,
      'Stop requested. Started side effects may still exist.',
    );
    expect(channel.cancelRequests, 1);
    expect(channel.stopRequests, 1);
  });

  test('settings command returns the local settings route', () {
    final channel = mineruReadyProfileChannel();

    final result = dispatcher.dispatch(
      channel,
      const LocalCommandIntent.openSettings(),
    );

    expect(result.consumed, isTrue);
    expect(result.routeLocation, AppRoutes.settings);
    expect(result.message, isNull);
  });

  test(
    'switch profile command selects contact and returns chat route plus copy',
    () {
      final channel = mineruReadyProfileChannel();
      final result = dispatcher.dispatch(
        channel,
        LocalCommandIntent.switchProfile(chatSupportTriageContact),
      );

      expectSelectedProfileScope(
        channel,
        serverId: 'office',
        profileId: 'support',
      );
      expect(result.routeLocation, '/chats/office/support');
      expect(result.message, 'Switched to Support Triage.');
    },
  );

  test('message-only command intents return snackbar copy', () {
    final channel = mineruReadyProfileChannel();

    final disabled = dispatcher.dispatch(
      channel,
      const LocalCommandIntent.profileSwitchingDisabled(),
    );
    final disambiguate = dispatcher.dispatch(
      channel,
      LocalCommandIntent.disambiguateProfile('mineru'),
    );
    final unknown = dispatcher.dispatch(
      channel,
      LocalCommandIntent.unknown('nope'),
    );

    expect(disabled.message, 'Voice profile switching is disabled.');
    expect(disambiguate.message, 'Choose one profile named mineru.');
    expect(unknown.message, 'Voice command not recognized: nope.');
    expect(channel.sentTexts, isEmpty);
  });
}
