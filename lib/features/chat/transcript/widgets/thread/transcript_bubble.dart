import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/channel/navivox_channel.dart';
import '../../../../../core/protocol/navivox_event.dart';
import '../../../../../shared/voice/text_to_speech_service.dart';
import '../../../../shared/presentation/conversation_time_labels.dart';
import '../../../../voice/widgets/voice_morph_surface.dart';
import '../../actions/transcript_message_action_coordinator.dart';
import '../../presentation/transcript_message_action_presentation.dart';
import '../../presentation/transcript_safety_notice_presentation.dart';
import '../../presentation/transcript_tool_call_presentation.dart';
import '../../presentation/transcript_voice_message_presentation.dart';
import '../transcript_message_action_sheet.dart';
import 'transcript_text_message_body.dart';

class TranscriptBubble extends StatelessWidget {
  const TranscriptBubble({
    required this.message,
    required this.isUser,
    required this.showTail,
    this.forwardTargets = const [],
    this.onForward,
    this.onInspectRunRecord,
    this.textToSpeechService,
    this.onCancelActiveTurn,
    super.key,
  });

  final NavivoxChatMessage message;
  final bool isUser;
  final bool showTail;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;
  final FutureOr<void> Function(NavivoxChatMessage message)? onInspectRunRecord;
  final TextToSpeechService? textToSpeechService;
  final VoidCallback? onCancelActiveTurn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final textColor = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final timeColor = isUser
        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6)
        : theme.colorScheme.onSurfaceVariant;

    return _TelegramReactionSurface(
      isUser: isUser,
      onLongPress: () => _showMessageActions(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tailWidth = showTail ? 12.0 : 0.0;
            final availableWidth = constraints.maxWidth - tailWidth;
            final maxBubbleWidth = availableWidth < 720
                ? availableWidth * 0.78
                : availableWidth.clamp(0, 720).toDouble() * 0.70;
            return Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser && showTail)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CustomPaint(
                      size: const Size(8, 12),
                      painter: _BubbleTailPainter(
                        color: bubbleColor,
                        flip: false,
                      ),
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(
                          isUser ? 16 : (showTail ? 4 : 16),
                        ),
                        bottomRight: Radius.circular(
                          isUser ? (showTail ? 4 : 16) : 16,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MessageBody(message: message, textColor: textColor),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  conversationMessageTimeLabel(
                                    message.createdAt,
                                  ),
                                  style: TextStyle(
                                    color: timeColor,
                                    fontSize: 11,
                                  ),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 3),
                                  Semantics(
                                    container: true,
                                    label: 'Sent',
                                    child: ExcludeSemantics(
                                      child: Icon(
                                        Icons.done_all,
                                        size: 14,
                                        color: timeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isUser && showTail)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: CustomPaint(
                      size: const Size(8, 12),
                      painter: _BubbleTailPainter(
                        color: bubbleColor,
                        flip: true,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showMessageActions(BuildContext context) {
    const actionCoordinator = TranscriptMessageActionCoordinator();
    final tts = textToSpeechService;
    final canCancel =
        onCancelActiveTurn != null &&
        message.author == NavivoxMessageAuthor.assistant;
    final runRecordAction = onInspectRunRecord;
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      message,
      textToSpeechAvailable: tts != null,
      canCancelActiveTurn: canCancel,
      forwardTargets: forwardTargets,
      forwardingAvailable: onForward != null,
      runRecordInspectionAvailable: runRecordAction != null,
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.52,
        minChildSize: 0.28,
        maxChildSize: 0.92,
        builder: (sheetContext, scrollController) =>
            TranscriptMessageActionSheet(
              presentation: presentation,
              scrollController: scrollController,
              onPauseStream: !canCancel
                  ? null
                  : () => _applyMessageActionEffect(
                      sheetContext: sheetContext,
                      rootContext: context,
                      effect: actionCoordinator.pauseStream(presentation),
                    ),
              onCopyText: () => _applyMessageActionEffect(
                sheetContext: sheetContext,
                rootContext: context,
                effect: actionCoordinator.copyText(presentation),
              ),
              onReadAloud: tts == null
                  ? null
                  : () => _applyMessageActionEffect(
                      sheetContext: sheetContext,
                      rootContext: context,
                      effect: actionCoordinator.readAloud(presentation),
                    ),
              onInspectRunRecord: runRecordAction == null
                  ? null
                  : () => _applyMessageActionEffect(
                      sheetContext: sheetContext,
                      rootContext: context,
                      effect: actionCoordinator.inspectRunRecord(message),
                    ),
              onForward: (target) => _applyMessageActionEffect(
                sheetContext: sheetContext,
                rootContext: context,
                effect: actionCoordinator.forward(message, target),
              ),
            ),
      ),
    );
  }

  Future<void> _applyMessageActionEffect({
    required BuildContext sheetContext,
    required BuildContext rootContext,
    required TranscriptMessageActionEffect effect,
  }) async {
    switch (effect) {
      case PauseStreamMessageActionEffect(:final snackbarMessage):
        Navigator.of(sheetContext).pop();
        onCancelActiveTurn?.call();
        ScaffoldMessenger.maybeOf(
          rootContext,
        )?.showSnackBar(SnackBar(content: Text(snackbarMessage)));
      case CopyTextMessageActionEffect(:final text, :final snackbarMessage):
        await Clipboard.setData(ClipboardData(text: text));
        if (!sheetContext.mounted) return;
        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.maybeOf(
          rootContext,
        )?.showSnackBar(SnackBar(content: Text(snackbarMessage)));
      case ReadAloudMessageActionEffect(:final text, :final snackbarMessage):
        await textToSpeechService?.speak(text);
        if (!sheetContext.mounted) return;
        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.maybeOf(
          rootContext,
        )?.showSnackBar(SnackBar(content: Text(snackbarMessage)));
      case InspectRunRecordMessageActionEffect(:final message):
        Navigator.of(sheetContext).pop();
        await onInspectRunRecord?.call(message);
      case ForwardMessageActionEffect(:final message, :final target):
        Navigator.of(sheetContext).pop();
        onForward?.call(message, target);
    }
  }
}

class _TelegramReactionSurface extends StatefulWidget {
  const _TelegramReactionSurface({
    required this.child,
    required this.isUser,
    required this.onLongPress,
  });

  final Widget child;
  final bool isUser;
  final VoidCallback onLongPress;

  @override
  State<_TelegramReactionSurface> createState() =>
      _TelegramReactionSurfaceState();
}

class _TelegramReactionSurfaceState extends State<_TelegramReactionSurface> {
  static const _doubleTapWindow = Duration(milliseconds: 320);
  static const _doubleTapSlop = 48.0;

  bool _hearted = false;
  DateTime? _lastTapAt;
  Offset? _lastTapPosition;

  void _handlePointerUp(Offset position) {
    final now = DateTime.now();
    final lastTapAt = _lastTapAt;
    final lastTapPosition = _lastTapPosition;
    final isDoubleTap =
        lastTapAt != null &&
        now.difference(lastTapAt) <= _doubleTapWindow &&
        lastTapPosition != null &&
        (position - lastTapPosition).distance <= _doubleTapSlop;

    _lastTapAt = now;
    _lastTapPosition = position;

    if (isDoubleTap) {
      _lastTapAt = null;
      _lastTapPosition = null;
      setState(() => _hearted = !_hearted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (event) => _handlePointerUp(event.position),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: widget.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.child,
            if (_hearted)
              Container(
                key: const ValueKey('transcript-local-reaction'),
                margin: EdgeInsets.only(
                  left: widget.isUser ? 0 : 24,
                  right: widget.isUser ? 24 : 0,
                  bottom: 2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                child: const Text('❤️', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color, required this.flip});

  final Color color;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (flip) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height * 0.6);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height * 0.6);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) =>
      color != oldDelegate.color || flip != oldDelegate.flip;
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message, this.textColor});

  final NavivoxChatMessage message;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return switch (message.kind) {
      NavivoxMessageKind.text => TranscriptTextMessageBody(
        message: message,
        textColor: textColor,
      ),
      NavivoxMessageKind.toolCall => _ToolCallBody(
        toolCall: message.toolCall!,
        textColor: textColor,
      ),
      NavivoxMessageKind.voice => _VoiceBody(
        voice: message.voice!,
        textColor: textColor,
      ),
      NavivoxMessageKind.safetyWarning => _SafetyNoticeBody(
        notice: message.safetyNotice!,
        approval: false,
        textColor: textColor,
      ),
      NavivoxMessageKind.approvalRequest => _SafetyNoticeBody(
        notice: message.safetyNotice!,
        approval: true,
        textColor: textColor,
      ),
    };
  }
}

class _ToolCallBody extends StatelessWidget {
  const _ToolCallBody({required this.toolCall, this.textColor});

  final NavivoxToolCall toolCall;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final presentation = TranscriptToolCallPresentation.fromToolCall(toolCall);
    final statusColor = _statusColor(presentation.statusTone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.build_circle,
              size: 16,
              color: textColor?.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              presentation.name,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                presentation.statusLabel,
                style: TextStyle(color: statusColor, fontSize: 11),
              ),
            ),
          ],
        ),
        if (presentation.showSummary) ...[
          const SizedBox(height: 4),
          Text(
            presentation.summary,
            style: TextStyle(
              color: textColor?.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
        if (presentation.showApproval) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  presentation.approvalLabel!,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (presentation.approvalPrompt?.isNotEmpty == true)
                  Text(
                    presentation.approvalPrompt!,
                    style: TextStyle(
                      color: textColor?.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                if (presentation.approvalRisk?.isNotEmpty == true)
                  Text(
                    presentation.approvalRisk!,
                    style: TextStyle(
                      color: textColor?.withValues(alpha: 0.65),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
        for (final artifact in presentation.artifacts) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.attachment,
                size: 14,
                color: textColor?.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          artifact.title,
                          style: TextStyle(
                            color: textColor?.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          artifact.kind,
                          style: TextStyle(
                            color: textColor?.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (artifact.showSummary)
                      Text(
                        artifact.summary!,
                        style: TextStyle(
                          color: textColor?.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    if (artifact.showRef)
                      Text(
                        artifact.ref!,
                        style: TextStyle(
                          color: textColor?.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

Color _statusColor(TranscriptToolCallStatusTone tone) {
  return switch (tone) {
    TranscriptToolCallStatusTone.active => Colors.orange,
    TranscriptToolCallStatusTone.success => Colors.green,
    TranscriptToolCallStatusTone.failure => Colors.red,
    TranscriptToolCallStatusTone.neutral => Colors.grey,
  };
}

Color _safetyNoticeAccent(ThemeData theme, TranscriptSafetyNoticeTone tone) {
  return switch (tone) {
    TranscriptSafetyNoticeTone.approval => theme.colorScheme.tertiary,
    TranscriptSafetyNoticeTone.warning => theme.colorScheme.error,
  };
}

IconData _safetyNoticeIcon(TranscriptSafetyNoticeTone tone) {
  return switch (tone) {
    TranscriptSafetyNoticeTone.approval => Icons.verified_user_outlined,
    TranscriptSafetyNoticeTone.warning => Icons.warning_amber,
  };
}

class _SafetyNoticeBody extends StatelessWidget {
  const _SafetyNoticeBody({
    required this.notice,
    required this.approval,
    this.textColor,
  });

  final NavivoxSafetyNotice notice;
  final bool approval;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = TranscriptSafetyNoticePresentation.fromNotice(
      notice,
      approval: approval,
    );
    final accent = _safetyNoticeAccent(theme, presentation.tone);
    return Container(
      key: ValueKey(presentation.cardKeyValue),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _safetyNoticeIcon(presentation.tone),
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                presentation.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (presentation.showSeverity) ...[
                const SizedBox(width: 8),
                Text(
                  presentation.severityLabel!,
                  style: TextStyle(color: accent, fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            presentation.message,
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          if (presentation.showRisk) ...[
            const SizedBox(height: 4),
            Text(
              presentation.risk!,
              style: TextStyle(
                color: textColor?.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceBody extends StatelessWidget {
  const _VoiceBody({required this.voice, this.textColor});

  final NavivoxVoiceMessage voice;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final presentation = TranscriptVoiceMessagePresentation.fromVoice(voice);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceMorphSurface(
          state: VoiceMorphState.speaking,
          intensity: presentation.morphIntensity,
          size: 40,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              presentation.title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            _TelegramVoiceWaveform(
              duration: voice.duration,
              confidence: voice.confidence,
              color: textColor,
            ),
            const SizedBox(height: 3),
            Text(
              presentation.durationLabel,
              style: TextStyle(
                color: textColor?.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            if (presentation.showTranscript)
              Text(
                presentation.transcript,
                style: TextStyle(
                  color: textColor?.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ],
    );
  }
}

class _TelegramVoiceWaveform extends StatelessWidget {
  const _TelegramVoiceWaveform({
    required this.duration,
    required this.confidence,
    this.color,
  });

  final Duration duration;
  final double confidence;
  final Color? color;

  List<double> get _bars {
    final seed =
        duration.inMilliseconds + (confidence.clamp(0.0, 1.0) * 100).round();
    return List<double>.generate(22, (index) {
      final wave = ((seed + index * 37) % 11) / 10;
      final pulse = index.isEven ? 0.18 : 0.0;
      return (0.22 + wave * 0.62 + pulse).clamp(0.18, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      key: const ValueKey('transcript-voice-waveform'),
      width: 116,
      height: 24,
      child: CustomPaint(
        painter: _VoiceWaveformPainter(
          bars: _bars,
          color: foreground.withValues(alpha: 0.48),
          accent: Theme.of(context).colorScheme.primary.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _VoiceWaveformPainter extends CustomPainter {
  const _VoiceWaveformPainter({
    required this.bars,
    required this.color,
    required this.accent,
  });

  final List<double> bars;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final unit = size.width / bars.length;
    final barWidth = unit * 0.56;
    final activeBars = (bars.length * 0.28).round();
    for (var index = 0; index < bars.length; index += 1) {
      final barHeight = size.height * bars[index].clamp(0.18, 1.0);
      final left = index * unit + (unit - barWidth) / 2;
      final top = (size.height - barHeight) / 2;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      final paint = Paint()
        ..color = index < activeBars ? accent : color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceWaveformPainter oldDelegate) =>
      bars != oldDelegate.bars ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}
