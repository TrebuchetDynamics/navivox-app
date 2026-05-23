import 'package:flutter/material.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../voice/services/text_to_speech_service.dart';
import '../transcript_thread_presentation.dart';
import 'transcript_bubble.dart';

class TranscriptThread extends StatelessWidget {
  const TranscriptThread({
    required this.messages,
    required this.scrollController,
    this.assistantTypingLabel,
    this.forwardTargets = const [],
    this.onForward,
    this.textToSpeechService,
    this.onCancelActiveTurn,
    super.key,
  });

  final List<NavivoxChatMessage> messages;
  final ScrollController scrollController;
  final String? assistantTypingLabel;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;
  final TextToSpeechService? textToSpeechService;
  final VoidCallback? onCancelActiveTurn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = TranscriptThreadPresentation.fromMessages(
      messages,
      assistantTypingLabel: assistantTypingLabel,
    );
    if (presentation.showEmptyState) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              presentation.emptyStateTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: presentation.itemCount,
      itemBuilder: (context, index) {
        if (index == presentation.rows.length) {
          return _TypingIndicator(label: presentation.typingIndicatorLabel!);
        }
        final row = presentation.rows[index];
        return TranscriptBubble(
          message: row.message,
          isUser: row.isUser,
          showTail: row.showTail,
          forwardTargets: forwardTargets,
          onForward: onForward,
          textToSpeechService: textToSpeechService,
          onCancelActiveTurn: row.canCancelActiveTurn
              ? onCancelActiveTurn
              : null,
        );
      },
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('assistant-typing-indicator'),
        margin: const EdgeInsets.only(top: 4, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
