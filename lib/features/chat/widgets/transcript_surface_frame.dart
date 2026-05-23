import 'package:flutter/material.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../voice/services/text_to_speech_service.dart';
import '../../voice/services/voice_capture_service.dart';
import 'transcript_input_panel.dart';
import 'transcript_thread.dart';

class TranscriptSurfaceFrame extends StatefulWidget {
  const TranscriptSurfaceFrame({
    required this.messages,
    required this.onSend,
    this.voiceCaptureService,
    this.onVoice,
    this.onVoiceCaptureStarted,
    this.onVoiceCaptureFailed,
    this.voiceCaptureTimeout = const Duration(seconds: 30),
    this.voiceUnavailableReason,
    this.voiceRecoveryAction,
    this.onOpenVoiceSettings,
    this.textToSpeechService,
    this.assistantTypingLabel,
    this.onCancelActiveTurn,
    this.forwardTargets = const [],
    this.onForward,
    super.key,
  });

  final List<NavivoxChatMessage> messages;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceCaptureService;
  final ValueChanged<VoiceCapture>? onVoice;
  final VoidCallback? onVoiceCaptureStarted;
  final ValueChanged<Object>? onVoiceCaptureFailed;
  final Duration voiceCaptureTimeout;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final VoidCallback? onOpenVoiceSettings;
  final TextToSpeechService? textToSpeechService;
  final String? assistantTypingLabel;
  final VoidCallback? onCancelActiveTurn;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;

  @override
  State<TranscriptSurfaceFrame> createState() => _TranscriptSurfaceFrameState();
}

class _TranscriptSurfaceFrameState extends State<TranscriptSurfaceFrame> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void didUpdateWidget(TranscriptSurfaceFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TranscriptThread(
            messages: widget.messages,
            scrollController: _scrollController,
            assistantTypingLabel: widget.assistantTypingLabel,
            forwardTargets: widget.forwardTargets,
            onForward: widget.onForward,
            textToSpeechService: widget.textToSpeechService,
            onCancelActiveTurn: widget.onCancelActiveTurn,
          ),
        ),
        TranscriptInputPanel(
          controller: _controller,
          onSend: widget.onSend,
          voiceCaptureService: widget.voiceCaptureService,
          onVoice: widget.onVoice,
          onVoiceCaptureStarted: widget.onVoiceCaptureStarted,
          onVoiceCaptureFailed: widget.onVoiceCaptureFailed,
          voiceCaptureTimeout: widget.voiceCaptureTimeout,
          voiceUnavailableReason: widget.voiceUnavailableReason,
          voiceRecoveryAction: widget.voiceRecoveryAction,
          onOpenVoiceSettings: widget.onOpenVoiceSettings,
        ),
      ],
    );
  }
}
