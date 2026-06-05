import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/protocol/navivox_event.dart';
import '../../presentation/transcript_text_message_presentation.dart';

class TranscriptTextMessageBody extends StatelessWidget {
  const TranscriptTextMessageBody({
    required this.message,
    this.textColor,
    super.key,
  });

  final NavivoxChatMessage message;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final presentation = TranscriptTextMessagePresentation.fromMessage(message);
    final content = TranscriptTextContentPresentation.fromText(
      presentation.text,
    );
    final linkPreview = content.linkPreview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TelegramFormattedText(content: content, textColor: textColor),
        if (linkPreview != null) ...[
          const SizedBox(height: 8),
          _TelegramLinkPreview(linkPreview: linkPreview, textColor: textColor),
        ],
      ],
    );
  }
}

class _TelegramFormattedText extends StatelessWidget {
  const _TelegramFormattedText({required this.content, this.textColor});

  final TranscriptTextContentPresentation content;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final segments = content.segments;
    if (content.isSinglePlainTextSegment) {
      return _TelegramExpandableText(text: content.text, textColor: textColor);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final segment in segments) ...[
          if (segment.isCode)
            _TelegramCodeBlock(segment: segment, textColor: textColor)
          else if (segment.isQuote)
            _TelegramBlockquote(segment: segment, textColor: textColor)
          else if (segment.isBulletList)
            _TelegramBulletList(segment: segment, textColor: textColor)
          else if (segment.isNumberedList)
            _TelegramNumberedList(segment: segment, textColor: textColor)
          else
            _TelegramExpandableText(text: segment.text, textColor: textColor),
          if (segment != segments.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _TelegramBlockquote extends StatelessWidget {
  const _TelegramBlockquote({required this.segment, this.textColor});

  final TranscriptTextSegment segment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = textColor ?? theme.colorScheme.onSurface;
    final accent = theme.colorScheme.primary;
    return Container(
      key: const ValueKey('transcript-blockquote'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: accent, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: _TelegramInlineText(
        text: segment.text,
        textColor: foreground.withValues(alpha: 0.82),
      ),
    );
  }
}

class _TelegramBulletList extends StatelessWidget {
  const _TelegramBulletList({required this.segment, this.textColor});

  final TranscriptTextSegment segment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = textColor ?? theme.colorScheme.onSurface;
    final markerColor = theme.colorScheme.primary;
    final items = segment.bulletItems ?? const <String>[];
    return Column(
      key: const ValueKey('transcript-bullet-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 8),
                  child: Container(
                    key: const ValueKey('transcript-bullet-marker'),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: _TelegramInlineText(text: item, textColor: foreground),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TelegramNumberedList extends StatelessWidget {
  const _TelegramNumberedList({required this.segment, this.textColor});

  final TranscriptTextSegment segment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = textColor ?? theme.colorScheme.onSurface;
    final markerColor = theme.colorScheme.primary;
    final items = segment.numberedItems ?? const <String>[];
    return Column(
      key: const ValueKey('transcript-numbered-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index += 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${segment.startNumber + index}.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: markerColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TelegramInlineText(
                    text: items[index],
                    textColor: foreground,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TelegramCodeBlock extends StatelessWidget {
  const _TelegramCodeBlock({required this.segment, this.textColor});

  final TranscriptTextSegment segment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = textColor ?? theme.colorScheme.onSurface;
    final background = foreground.withValues(alpha: 0.08);
    return Container(
      key: const ValueKey('transcript-code-block'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: foreground.withValues(alpha: 0.10)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    segment.language ?? 'code',
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.64),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: segment.text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    color: foreground.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: SelectableText(
              segment.text,
              style: TextStyle(
                color: foreground,
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelegramInlineText extends StatelessWidget {
  const _TelegramInlineText({
    required this.text,
    this.textColor,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final Color? textColor;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final spans = _inlineSpans(context);
    if (spans == null) {
      return Text(
        text,
        key: const ValueKey('transcript-expandable-text'),
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(color: textColor, fontSize: 15),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      key: const ValueKey('transcript-formatted-inline-text'),
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(color: textColor, fontSize: 15),
    );
  }

  List<InlineSpan>? _inlineSpans(BuildContext context) {
    final tokens = TranscriptInlineToken.parse(text);
    if (tokens.length == 1 &&
        tokens.single.kind == TranscriptInlineTokenKind.plain) {
      return null;
    }
    final accent = Theme.of(context).colorScheme.primary;
    return [for (final token in tokens) _formattedSpan(token, accent)];
  }

  TextSpan _accentSpan(String text, Color accent) => TextSpan(
    text: text,
    style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w700),
  );

  TextSpan _formattedSpan(TranscriptInlineToken token, Color accent) {
    final baseStyle = TextStyle(color: textColor, fontSize: 15);
    return switch (token.kind) {
      TranscriptInlineTokenKind.plain => TextSpan(
        text: token.text,
        style: baseStyle,
      ),
      TranscriptInlineTokenKind.bold => TextSpan(
        text: token.text,
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ),
      TranscriptInlineTokenKind.italic => TextSpan(
        text: token.text,
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ),
      TranscriptInlineTokenKind.code => TextSpan(
        text: token.text,
        style: baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: (textColor ?? Colors.black).withValues(alpha: 0.10),
        ),
      ),
      TranscriptInlineTokenKind.strike => TextSpan(
        text: token.text,
        style: baseStyle.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: textColor,
        ),
      ),
      TranscriptInlineTokenKind.accent ||
      TranscriptInlineTokenKind.detected => _accentSpan(token.text, accent),
    };
  }
}

class _TelegramExpandableText extends StatefulWidget {
  const _TelegramExpandableText({required this.text, this.textColor});

  final String text;
  final Color? textColor;

  @override
  State<_TelegramExpandableText> createState() =>
      _TelegramExpandableTextState();
}

class _TelegramExpandableTextState extends State<_TelegramExpandableText> {
  bool _expanded = false;

  bool get _shouldCollapse =>
      TranscriptTextCollapsePolicy.shouldCollapse(widget.text);

  @override
  void didUpdateWidget(covariant _TelegramExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldClamp = _shouldCollapse && !_expanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TelegramInlineText(
          text: widget.text,
          textColor: widget.textColor,
          maxLines: shouldClamp
              ? TranscriptTextCollapsePolicy.collapsedMaxLines
              : null,
          overflow: shouldClamp ? TextOverflow.fade : null,
        ),
        if (_shouldCollapse)
          TextButton(
            key: const ValueKey('transcript-expand-text-toggle'),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(top: 4),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Show more',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _TelegramLinkPreview extends StatelessWidget {
  const _TelegramLinkPreview({required this.linkPreview, this.textColor});

  final TranscriptLinkPreviewPresentation linkPreview;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final foreground = textColor ?? theme.colorScheme.onSurface;
    return Semantics(
      label: 'Link preview for ${linkPreview.host}',
      child: Container(
        key: const ValueKey('transcript-link-preview'),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.06),
          border: Border(left: BorderSide(color: accent, width: 3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              linkPreview.host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              linkPreview.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.72),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
