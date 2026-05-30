import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

/// Voice capture test double that fails every capture with the configured error.
class ThrowingVoiceCaptureService implements VoiceCaptureService {
  const ThrowingVoiceCaptureService(this.error);

  final Object error;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    throw error;
  }
}
