import '../voice/services/voice_capture_service.dart';

enum TranscriptVoiceCaptureStatus { unavailable, captured, failed }

class TranscriptVoiceCaptureOutcome {
  const TranscriptVoiceCaptureOutcome._({
    required this.status,
    this.capture,
    this.error,
    this.errorMessage,
  });

  const TranscriptVoiceCaptureOutcome.unavailable()
    : this._(status: TranscriptVoiceCaptureStatus.unavailable);

  const TranscriptVoiceCaptureOutcome.captured(VoiceCapture capture)
    : this._(status: TranscriptVoiceCaptureStatus.captured, capture: capture);

  const TranscriptVoiceCaptureOutcome.failed({
    required Object error,
    required String errorMessage,
  }) : this._(
         status: TranscriptVoiceCaptureStatus.failed,
         error: error,
         errorMessage: errorMessage,
       );

  final TranscriptVoiceCaptureStatus status;
  final VoiceCapture? capture;
  final Object? error;
  final String? errorMessage;
}

class TranscriptVoiceCaptureFlow {
  const TranscriptVoiceCaptureFlow();

  Future<TranscriptVoiceCaptureOutcome> capture({
    required VoiceCaptureService? service,
    required Duration timeout,
    void Function()? onStarted,
  }) async {
    if (service == null) {
      return const TranscriptVoiceCaptureOutcome.unavailable();
    }

    onStarted?.call();
    try {
      final capture = await service.capture(timeout: timeout);
      return TranscriptVoiceCaptureOutcome.captured(capture);
    } on VoiceCaptureTimeout catch (error) {
      return TranscriptVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: 'Voice capture timed out.',
      );
    } catch (error) {
      return TranscriptVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: 'Voice capture failed: $error',
      );
    }
  }
}
