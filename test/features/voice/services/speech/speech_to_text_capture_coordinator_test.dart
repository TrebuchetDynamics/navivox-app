import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:navivox/core/protocol/voice_unavailable_reason.dart';
import 'package:navivox/features/voice/services/speech/speech_to_text_capture_coordinator.dart';
import 'package:navivox/features/voice/services/speech/speech_to_text_capture_policy.dart';
import 'package:navivox/shared/voice/voice_capture_failures.dart';

void main() {
  const coordinator = SpeechToTextCaptureCoordinator();

  test('maps initialize availability through permission diagnostic', () {
    expect(
      coordinator.unavailableReasonForInitialize(
        permissionBeforeInitialize: false,
      ),
      microphonePermissionDeniedReason,
    );
    expect(
      coordinator.unavailableReasonForInitialize(
        permissionBeforeInitialize: null,
      ),
      deviceSttUnavailableReason,
    );
  });

  test('plans terminal status completion or no-transcript failure', () {
    const snapshot = SpeechToTextSnapshot(
      words: 'hello',
      confidence: 0.5,
      finalResult: false,
    );

    expect(
      coordinator.terminalStatusPlan(
        status: 'listening',
        latestTranscript: snapshot,
      ),
      isA<IgnoreSpeechToTextTerminalStatusPlan>(),
    );
    final complete = coordinator.terminalStatusPlan(
      status: 'done',
      latestTranscript: snapshot,
    );
    expect(complete, isA<CompleteSpeechToTextTerminalStatusPlan>());
    expect(
      (complete as CompleteSpeechToTextTerminalStatusPlan).snapshot,
      snapshot,
    );

    final fail = coordinator.terminalStatusPlan(
      status: 'notListening',
      latestTranscript: null,
    );
    expect(fail, isA<FailSpeechToTextTerminalStatusPlan>());
    expect(
      (fail as FailSpeechToTextTerminalStatusPlan).error,
      isA<SpeechToTextCaptureFailure>(),
    );
  });

  test('normalizes platform errors into voice failures', () {
    expect(
      coordinator.normalizeError(
        SpeechRecognitionError('error_no_match', true),
      ),
      isA<SpeechToTextCaptureFailure>(),
    );
    expect(
      coordinator.normalizeError(SpeechRecognitionError('notAllowed', true)),
      isA<DeviceSpeechUnavailable>().having(
        (error) => error.message,
        'message',
        microphonePermissionDeniedReason,
      ),
    );
    expect(
      coordinator.normalizeError(
        stt.ListenFailedException('No speech recognition service available'),
      ),
      isA<DeviceSpeechUnavailable>().having(
        (error) => error.message,
        'message',
        deviceSttUnavailableReason,
      ),
    );
  });

  test('formats diagnostics without exposing plugin objects directly', () {
    expect(
      coordinator.errorDiagnostic(SpeechRecognitionError('notAllowed', true)),
      'error errorMsg=notAllowed permanent=true',
    );
    expect(coordinator.errorDiagnostic('boom'), 'error=boom');
  });
}
