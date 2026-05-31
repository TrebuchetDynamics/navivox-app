import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_message_plain_text_presentation.dart';

import '../../../shared/transcript_test_fixtures.dart';
import '../../shared/transcript_message_text_projection_cases.dart';
import '../shared/transcript_display_text_expectations.dart';

void main() {
  test('projects transcript messages into shared plain text cases', () {
    for (final testCase in transcriptMessageTextProjectionCases()) {
      final presentation = TranscriptMessagePlainTextPresentation.fromMessage(
        testCase.message,
      );

      expectTranscriptDisplayText(
        actualText: presentation.text,
        actualIsVisible: presentation.hasText,
        expectedText: testCase.expectedText,
        reason: testCase.description,
      );
    }
  });

  test('omits empty optional lines and exposes empty state', () {
    final tool = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptToolMessage(
        toolCall: transcriptToolCall(name: '', status: '', summary: ''),
      ),
    );
    final missingVoice = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptChatMessage(kind: NavivoxMessageKind.voice),
    );
    final notice = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptNoticeMessage(
        kind: NavivoxMessageKind.safetyWarning,
        notice: transcriptSafetyNotice(id: 'safety-2', message: ''),
      ),
    );

    expectTranscriptDisplayText(
      actualText: tool.text,
      actualIsVisible: tool.hasText,
      expectedText: '',
    );
    expectTranscriptDisplayText(
      actualText: missingVoice.text,
      actualIsVisible: missingVoice.hasText,
      expectedText: '',
    );
    expectTranscriptDisplayText(
      actualText: notice.text,
      actualIsVisible: notice.hasText,
      expectedText: '',
    );
  });
}
