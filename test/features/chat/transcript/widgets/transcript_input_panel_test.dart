import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/shared/voice/voice_capture_failures.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import '../../../shared/fakes/voice_capture_service_fakes.dart';
import '../shared/transcript_controller_test_helpers.dart';
import '../shared/transcript_widget_test_app.dart';

void main() {
  testWidgets('sends typed text and clears the composer controller', (
    tester,
  ) async {
    final controller = transcriptTextController(text: 'hello Gormes');
    final sent = <String>[];

    await tester.pumpWidget(
      transcriptInputPanelTestApp(controller: controller, onSend: sent.add),
    );

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(sent, ['hello Gormes']);
    expect(controller.text, isEmpty);
  });

  testWidgets('captures voice and reports start before captured voice', (
    tester,
  ) async {
    final controller = transcriptTextController();
    final events = <String>[];
    VoiceCapture? captured;

    await tester.pumpWidget(
      transcriptInputPanelTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        voiceCaptureService: successfulVoiceCaptureService(audio: [1, 2, 3]),
        onVoiceCaptureStarted: () => events.add('started'),
        onVoice: (capture) {
          events.add('captured');
          captured = capture;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(events, ['started', 'captured']);
    expect(captured?.transcript, 'hello voice');
  });

  testWidgets('shows capture failure copy and reports failed capture', (
    tester,
  ) async {
    final controller = transcriptTextController();
    Object? failed;

    await tester.pumpWidget(
      transcriptInputPanelTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        voiceCaptureService: ThrowingVoiceCaptureService(
          StateError('microphone exploded'),
        ),
        onVoiceCaptureFailed: (error) => failed = error,
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(failed, isA<StateError>());
    expect(
      find.text('Voice capture failed: Bad state: microphone exploded'),
      findsOneWidget,
    );
  });

  testWidgets('shows actionable no-speech recovery copy', (tester) async {
    final controller = transcriptTextController();
    Object? failed;

    await tester.pumpWidget(
      transcriptInputPanelTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        voiceCaptureService: const ThrowingVoiceCaptureService(
          SpeechToTextCaptureFailure('no transcript'),
        ),
        onVoiceCaptureFailed: (error) => failed = error,
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(failed, isA<SpeechToTextCaptureFailure>());
    expect(find.text(noSpeechDetectedVoiceCaptureMessage), findsOneWidget);
  });

  testWidgets('shows actionable permission recovery copy', (tester) async {
    final controller = transcriptTextController();
    Object? failed;

    await tester.pumpWidget(
      transcriptInputPanelTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        voiceCaptureService: const ThrowingVoiceCaptureService(
          DeviceSpeechUnavailable('microphone permission denied'),
        ),
        onVoiceCaptureFailed: (error) => failed = error,
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(failed, isA<DeviceSpeechUnavailable>());
    expect(
      find.text(microphonePermissionDeniedVoiceCaptureMessage),
      findsOneWidget,
    );
  });

  testWidgets('shows stop state while capture is in flight', (tester) async {
    final controller = transcriptTextController();

    await tester.pumpWidget(
      transcriptInputPanelTestApp(
        controller: controller,
        onSend: transcriptNoopSend,
        voiceCaptureService: successfulVoiceCaptureService(
          transcript: 'slow voice',
          duration: const Duration(milliseconds: 50),
          confidence: 1,
          captureLatency: const Duration(milliseconds: 100),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);

    await tester.pumpAndSettle();
  });
}
