import 'package:flutter/widgets.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_surface.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';
import 'package:navivox/shared/voice/text_to_speech_service.dart';

import 'transcript_forwarding_contracts.dart';
import 'transcript_test_scaffold.dart';

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
  TextToSpeechService? textToSpeechService,
  List<NavivoxProfileContact> forwardTargets = const [],
  TranscriptForwardCallback? onForward,
}) {
  return transcriptTestScaffold(
    TranscriptSurface(
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
      textToSpeechService: textToSpeechService,
      forwardTargets: forwardTargets,
      onForward: onForward,
    ),
  );
}
