import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_text_message_presentation.dart';

import '../../../shared/transcript_test_fixtures.dart';
import '../shared/transcript_display_text_expectations.dart';

void main() {
  test('derives text message display state', () {
    final presentation = TranscriptTextMessagePresentation.fromMessage(
      transcriptTextMessage(
        text: 'hello profile contact',
        author: NavivoxMessageAuthor.user,
        createdAt: DateTime.utc(2026, 5, 23, 12),
      ),
    );

    expectTranscriptDisplayText(
      actualText: presentation.text,
      actualIsVisible: presentation.hasText,
      expectedText: 'hello profile contact',
    );
  });

  test('preserves operator text exactly without trimming', () {
    final presentation = TranscriptTextMessagePresentation.fromMessage(
      transcriptTextMessage(
        text: '  keep spacing  ',
        author: NavivoxMessageAuthor.user,
        createdAt: DateTime.utc(2026, 5, 23, 12),
      ),
    );

    expectTranscriptDisplayText(
      actualText: presentation.text,
      actualIsVisible: presentation.hasText,
      expectedText: '  keep spacing  ',
    );
  });

  test('normalizes missing text to empty display state', () {
    final presentation = TranscriptTextMessagePresentation.fromMessage(
      transcriptTextMessage(
        author: NavivoxMessageAuthor.user,
        createdAt: DateTime.utc(2026, 5, 23, 12),
      ),
    );

    expectTranscriptDisplayText(
      actualText: presentation.text,
      actualIsVisible: presentation.hasText,
      expectedText: '',
    );
  });
}
