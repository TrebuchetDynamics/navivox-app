import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/actions/chat_operator_action_coordinator.dart';
import 'package:navivox/features/chat/commands/local_command_dispatcher.dart';
import 'package:navivox/features/chat/forwarding/forward_message_intent.dart';
import 'package:navivox/features/chat/voice/controllers/voice_run_controller.dart';

void main() {
  const coordinator = ChatOperatorActionCoordinator();

  test('local command enter mode maps to command-mode effect only', () {
    final effects = coordinator.effectsForLocalCommandDispatch(
      const LocalCommandDispatchResult(consumed: true, enterCommandMode: true),
    );

    expect(effects, hasLength(1));
    expect(effects.single, isA<EnterCommandModeEffect>());
  });

  test('local command route and message exits command mode first', () {
    final effects = coordinator.effectsForLocalCommandDispatch(
      const LocalCommandDispatchResult(
        consumed: true,
        routeLocation: '/settings',
        message: 'Opened settings.',
      ),
    );

    expect(effects[0], isA<ExitCommandModeEffect>());
    expect((effects[0] as ExitCommandModeEffect).clearNotice, isFalse);
    expect(effects[1], isA<RouteChatEffect>());
    expect((effects[1] as RouteChatEffect).location, '/settings');
    expect(effects[2], isA<ShowCommandMessageEffect>());
    expect(
      (effects[2] as ShowCommandMessageEffect).message,
      'Opened settings.',
    );
  });

  test('local command cancel-pending voice emits cancellation effect', () {
    final effects = coordinator.effectsForLocalCommandDispatch(
      const LocalCommandDispatchResult(
        consumed: true,
        cancelPendingVoice: true,
      ),
    );

    expect(effects, hasLength(2));
    expect(effects[0], isA<ExitCommandModeEffect>());
    expect(effects[1], isA<CancelPendingVoiceEffect>());
  });

  test('voice capture schedules auto-send when a pending voice run exists', () {
    final effects = coordinator.effectsForVoiceCapture(
      const VoiceRunCaptureResult(
        handledLocalCommand: false,
        scheduleAutoSendFor: 'voice-1',
      ),
    );

    expect(effects[0], isA<RefreshChatUiEffect>());
    expect(effects[1], isA<ScheduleVoiceAutoSendEffect>());
    expect((effects[1] as ScheduleVoiceAutoSendEffect).voiceRunId, 'voice-1');
  });

  test('voice local command only refreshes UI', () {
    final effects = coordinator.effectsForVoiceCapture(
      const VoiceRunCaptureResult(handledLocalCommand: true),
    );

    expect(effects, hasLength(1));
    expect(effects.single, isA<RefreshChatUiEffect>());
  });

  test('forward result maps to route and snackbar effects', () {
    final effects = coordinator.effectsForForward(
      const ForwardMessageResult(
        forwarded: true,
        text: 'hello',
        routeLocation: '/chats/server/profile',
        snackbarMessage: 'Forwarded.',
      ),
    );

    expect(effects[0], isA<RouteChatEffect>());
    expect((effects[0] as RouteChatEffect).location, '/chats/server/profile');
    expect(effects[1], isA<ShowSnackbarEffect>());
    expect((effects[1] as ShowSnackbarEffect).message, 'Forwarded.');
  });

  test('run record unavailable is transient snackbar recovery', () {
    final effect = coordinator.runRecordUnavailableEffect();

    expect(effect, isA<ShowSnackbarEffect>());
    expect((effect as ShowSnackbarEffect).message, 'Run record unavailable.');
  });
}
