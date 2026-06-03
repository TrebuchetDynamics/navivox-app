import '../../../../core/channel/navivox_channel.dart';
import '../../../../core/protocol/navivox_event.dart';
import '../presentation/transcript_message_action_presentation.dart';

/// Converts Transcript message action taps into typed effects.
///
/// Widgets still own Flutter side effects such as Navigator, Clipboard,
/// ScaffoldMessenger, and TTS execution.
final class TranscriptMessageActionCoordinator {
  const TranscriptMessageActionCoordinator();

  TranscriptMessageActionEffect pauseStream(
    TranscriptMessageActionPresentation presentation,
  ) {
    return TranscriptMessageActionEffect.pauseStream(
      snackbarMessage: presentation.pauseSnackbar,
    );
  }

  TranscriptMessageActionEffect copyText(
    TranscriptMessageActionPresentation presentation,
  ) {
    return TranscriptMessageActionEffect.copyText(
      text: presentation.text,
      snackbarMessage: presentation.copySnackbar,
    );
  }

  TranscriptMessageActionEffect readAloud(
    TranscriptMessageActionPresentation presentation,
  ) {
    return TranscriptMessageActionEffect.readAloud(
      text: presentation.text,
      snackbarMessage: presentation.readAloudSnackbar,
    );
  }

  TranscriptMessageActionEffect inspectRunRecord(NavivoxChatMessage message) {
    return TranscriptMessageActionEffect.inspectRunRecord(message);
  }

  TranscriptMessageActionEffect forward(
    NavivoxChatMessage message,
    NavivoxProfileContact target,
  ) {
    return TranscriptMessageActionEffect.forward(
      message: message,
      target: target,
    );
  }
}

sealed class TranscriptMessageActionEffect {
  const TranscriptMessageActionEffect._();

  const factory TranscriptMessageActionEffect.pauseStream({
    required String snackbarMessage,
  }) = PauseStreamMessageActionEffect;

  const factory TranscriptMessageActionEffect.copyText({
    required String text,
    required String snackbarMessage,
  }) = CopyTextMessageActionEffect;

  const factory TranscriptMessageActionEffect.readAloud({
    required String text,
    required String snackbarMessage,
  }) = ReadAloudMessageActionEffect;

  const factory TranscriptMessageActionEffect.inspectRunRecord(
    NavivoxChatMessage message,
  ) = InspectRunRecordMessageActionEffect;

  const factory TranscriptMessageActionEffect.forward({
    required NavivoxChatMessage message,
    required NavivoxProfileContact target,
  }) = ForwardMessageActionEffect;
}

final class PauseStreamMessageActionEffect
    extends TranscriptMessageActionEffect {
  const PauseStreamMessageActionEffect({required this.snackbarMessage})
    : super._();

  final String snackbarMessage;
}

final class CopyTextMessageActionEffect extends TranscriptMessageActionEffect {
  const CopyTextMessageActionEffect({
    required this.text,
    required this.snackbarMessage,
  }) : super._();

  final String text;
  final String snackbarMessage;
}

final class ReadAloudMessageActionEffect extends TranscriptMessageActionEffect {
  const ReadAloudMessageActionEffect({
    required this.text,
    required this.snackbarMessage,
  }) : super._();

  final String text;
  final String snackbarMessage;
}

final class InspectRunRecordMessageActionEffect
    extends TranscriptMessageActionEffect {
  const InspectRunRecordMessageActionEffect(this.message) : super._();

  final NavivoxChatMessage message;
}

final class ForwardMessageActionEffect extends TranscriptMessageActionEffect {
  const ForwardMessageActionEffect({
    required this.message,
    required this.target,
  }) : super._();

  final NavivoxChatMessage message;
  final NavivoxProfileContact target;
}
