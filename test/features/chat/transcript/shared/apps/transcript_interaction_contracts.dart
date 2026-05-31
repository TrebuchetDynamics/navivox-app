import 'package:flutter/widgets.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

/// Shared callback contract for Transcript tests that submit composed text.
typedef TranscriptSendCallback = ValueChanged<String>;

/// Shared callback contract for Transcript tests that receive captured voice.
typedef TranscriptVoiceCaptureCallback = ValueChanged<VoiceCapture>;
