import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_voice_message_presentation.dart';

import '../../../shared/transcript_test_fixtures.dart';
import '../shared/transcript_display_text_expectations.dart';

void main() {
  test('derives Voice run bubble display state with transcript', () {
    final presentation = TranscriptVoiceMessagePresentation.fromVoice(
      transcriptVoice(
        transcript: 'hello voice',
        duration: const Duration(milliseconds: 1200),
        confidence: 0.91,
      ),
    );

    expect(presentation.title, 'Voice message');
    expect(presentation.durationLabel, '1s');
    expectTranscriptDisplayText(
      actualText: presentation.transcript,
      actualIsVisible: presentation.showTranscript,
      expectedText: 'hello voice',
    );
    expect(presentation.morphIntensity, 0.91);
  });

  test('omits transcript row when Voice run transcript is empty', () {
    final presentation = TranscriptVoiceMessagePresentation.fromVoice(
      transcriptVoice(
        duration: const Duration(milliseconds: 500),
        confidence: 0.42,
      ),
    );

    expect(presentation.title, 'Voice message');
    expect(presentation.durationLabel, '0s');
    expectTranscriptDisplayText(
      actualText: presentation.transcript,
      actualIsVisible: presentation.showTranscript,
      expectedText: '',
    );
    expect(presentation.morphIntensity, 0.42);
  });
}
