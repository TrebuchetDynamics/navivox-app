import 'package:flutter/widgets.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_surface.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

import '../../../shared/app/test_material_app.dart';

/// Mounts [TranscriptSurface] in the shared feature-test Material scaffold.
Widget transcriptSurfaceTestApp({
  required List<NavivoxChatMessage> messages,
  required ValueChanged<String> onSend,
  VoidCallback? onUploadFile,
  VoidCallback? onPickPhotoOrVideo,
  VoidCallback? onOpenWorkspace,
  String? voiceUnavailableReason,
  String? voiceRecoveryAction,
  VoidCallback? onOpenVoiceSettings,
  VoiceCaptureService? voiceCaptureService,
  ValueChanged<VoiceCapture>? onVoice,
}) {
  return TestMaterialScaffold(
    body: TranscriptSurface(
      messages: messages,
      onSend: onSend,
      onUploadFile: onUploadFile,
      onPickPhotoOrVideo: onPickPhotoOrVideo,
      onOpenWorkspace: onOpenWorkspace,
      voiceUnavailableReason: voiceUnavailableReason,
      voiceRecoveryAction: voiceRecoveryAction,
      onOpenVoiceSettings: onOpenVoiceSettings,
      voiceCaptureService: voiceCaptureService,
      onVoice: onVoice,
    ),
  );
}
