import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_message_plain_text_presentation.dart';

import '../shared/transcript_test_fixtures.dart';

void main() {
  test('projects text and Voice run messages into plain text', () {
    final text = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptTextMessage(text: 'copy this'),
    );
    final voice = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptVoiceMessage(transcript: 'captured voice'),
    );

    expect(text.text, 'copy this');
    expect(text.hasText, isTrue);
    expect(voice.text, 'captured voice');
    expect(voice.hasText, isTrue);
  });

  test('projects tool cards into name, status, and summary lines', () {
    final presentation = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptToolMessage(
        toolCall: const NavivoxToolCall(
          name: 'grep',
          status: 'finished',
          summary: 'Matched 2 files',
        ),
      ),
    );

    expect(presentation.text, 'grep\nfinished\nMatched 2 files');
    expect(presentation.hasText, isTrue);
  });

  test('projects safety and approval notices into message and risk lines', () {
    final safety = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptNoticeMessage(
        kind: NavivoxMessageKind.safetyWarning,
        notice: transcriptSafetyNotice(
          id: 'safety-1',
          message: 'Unsafe exposure',
          risk: 'Public gateway',
        ),
      ),
    );
    final approval = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptNoticeMessage(
        kind: NavivoxMessageKind.approvalRequest,
        notice: transcriptApprovalNotice(
          id: 'approval-1',
          message: 'Approve restart?',
          risk: 'Interrupts active run',
        ),
      ),
    );

    expect(safety.text, 'Unsafe exposure\nPublic gateway');
    expect(safety.hasText, isTrue);
    expect(approval.text, 'Approve restart?\nInterrupts active run');
    expect(approval.hasText, isTrue);
  });

  test('omits empty optional lines and exposes empty state', () {
    final tool = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptToolMessage(
        toolCall: const NavivoxToolCall(name: '', status: '', summary: ''),
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

    expect(tool.text, isEmpty);
    expect(tool.hasText, isFalse);
    expect(missingVoice.text, isEmpty);
    expect(missingVoice.hasText, isFalse);
    expect(notice.text, isEmpty);
    expect(notice.hasText, isFalse);
  });
}
