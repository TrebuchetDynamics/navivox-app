import '../../../../../core/protocol/navivox_event.dart';
import '../shared/transcript_display_text.dart';

class TranscriptTextMessagePresentation {
  const TranscriptTextMessagePresentation({required this.text});

  factory TranscriptTextMessagePresentation.fromMessage(
    NavivoxChatMessage message,
  ) {
    return TranscriptTextMessagePresentation(text: message.text ?? '');
  }

  final String text;

  bool get hasText => transcriptHasDisplayText(text);
}
