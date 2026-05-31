import '../../../../../core/protocol/navivox_event.dart';
import '../message/transcript_text_message_presentation.dart';
import 'transcript_display_text.dart';

class TranscriptMessagePlainTextPresentation {
  const TranscriptMessagePlainTextPresentation({required this.text});

  factory TranscriptMessagePlainTextPresentation.fromMessage(
    NavivoxChatMessage message,
  ) {
    return TranscriptMessagePlainTextPresentation(
      text: switch (message.kind) {
        NavivoxMessageKind.text =>
          TranscriptTextMessagePresentation.fromMessage(message).text,
        NavivoxMessageKind.voice => message.voice?.transcript ?? '',
        NavivoxMessageKind.toolCall => transcriptJoinNonEmptyLines([
          message.toolCall?.name,
          message.toolCall?.status,
          message.toolCall?.summary,
        ]),
        NavivoxMessageKind.safetyWarning ||
        NavivoxMessageKind.approvalRequest => transcriptJoinNonEmptyLines([
          message.safetyNotice?.message,
          message.safetyNotice?.risk,
        ]),
      },
    );
  }

  final String text;

  bool get hasText => transcriptHasDisplayText(text);
}
