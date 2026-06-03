import '../commands/local_command_dispatcher.dart';
import '../forwarding/forward_message_intent.dart';
import '../voice/controllers/voice_run_controller.dart';

/// Coordinates ChatScreen operator-action results into UI/runtime effects.
///
/// ChatScreen still executes Flutter effects such as timers, route changes,
/// snackbars, and setState. This coordinator decides which effects are needed
/// after local commands, voice capture, forwarding, and evidence failures.
final class ChatOperatorActionCoordinator {
  const ChatOperatorActionCoordinator();

  List<ChatOperatorEffect> effectsForLocalCommandDispatch(
    LocalCommandDispatchResult result,
  ) {
    if (!result.consumed) return const [];
    if (result.enterCommandMode) {
      return const [ChatOperatorEffect.enterCommandMode()];
    }
    return [
      const ChatOperatorEffect.exitCommandMode(clearNotice: false),
      if (result.cancelPendingVoice)
        const ChatOperatorEffect.cancelPendingVoice(),
      if (result.routeLocation case final routeLocation?)
        ChatOperatorEffect.route(routeLocation),
      if (result.message case final message?)
        ChatOperatorEffect.showMessage(message),
    ];
  }

  List<ChatOperatorEffect> effectsForVoiceCapture(
    VoiceRunCaptureResult result,
  ) {
    if (result.handledLocalCommand) {
      return const [ChatOperatorEffect.refreshUi()];
    }
    final voiceRunId = result.scheduleAutoSendFor;
    if (voiceRunId == null) return const [];
    return [
      const ChatOperatorEffect.refreshUi(),
      ChatOperatorEffect.scheduleVoiceAutoSend(voiceRunId),
    ];
  }

  List<ChatOperatorEffect> effectsForForward(ForwardMessageResult result) {
    if (!result.forwarded) return const [];
    return [
      if (result.routeLocation case final routeLocation?)
        ChatOperatorEffect.route(routeLocation),
      if (result.snackbarMessage case final message?)
        ChatOperatorEffect.showSnackbar(message),
    ];
  }

  ChatOperatorEffect runRecordUnavailableEffect() {
    return const ChatOperatorEffect.showSnackbar('Run record unavailable.');
  }
}

sealed class ChatOperatorEffect {
  const ChatOperatorEffect._();

  const factory ChatOperatorEffect.enterCommandMode() = EnterCommandModeEffect;

  const factory ChatOperatorEffect.exitCommandMode({
    required bool clearNotice,
  }) = ExitCommandModeEffect;

  const factory ChatOperatorEffect.cancelPendingVoice() =
      CancelPendingVoiceEffect;

  const factory ChatOperatorEffect.route(String location) = RouteChatEffect;

  const factory ChatOperatorEffect.showMessage(String message) =
      ShowCommandMessageEffect;

  const factory ChatOperatorEffect.showSnackbar(String message) =
      ShowSnackbarEffect;

  const factory ChatOperatorEffect.scheduleVoiceAutoSend(String voiceRunId) =
      ScheduleVoiceAutoSendEffect;

  const factory ChatOperatorEffect.refreshUi() = RefreshChatUiEffect;
}

final class EnterCommandModeEffect extends ChatOperatorEffect {
  const EnterCommandModeEffect() : super._();
}

final class ExitCommandModeEffect extends ChatOperatorEffect {
  const ExitCommandModeEffect({required this.clearNotice}) : super._();

  final bool clearNotice;
}

final class CancelPendingVoiceEffect extends ChatOperatorEffect {
  const CancelPendingVoiceEffect() : super._();
}

final class RouteChatEffect extends ChatOperatorEffect {
  const RouteChatEffect(this.location) : super._();

  final String location;
}

final class ShowCommandMessageEffect extends ChatOperatorEffect {
  const ShowCommandMessageEffect(this.message) : super._();

  final String message;
}

final class ShowSnackbarEffect extends ChatOperatorEffect {
  const ShowSnackbarEffect(this.message) : super._();

  final String message;
}

final class ScheduleVoiceAutoSendEffect extends ChatOperatorEffect {
  const ScheduleVoiceAutoSendEffect(this.voiceRunId) : super._();

  final String voiceRunId;
}

final class RefreshChatUiEffect extends ChatOperatorEffect {
  const RefreshChatUiEffect() : super._();
}
