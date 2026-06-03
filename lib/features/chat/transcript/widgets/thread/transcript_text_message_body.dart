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
    final linkPreview = _TranscriptLinkPreview.maybeFrom(presentation.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TelegramFormattedText(text: presentation.text, textColor: textColor),
        if (linkPreview != null) ...[
          const SizedBox(height: 8),
          _TelegramLinkPreview(linkPreview: linkPreview, textColor: textColor),
        ],
      ],
    );
  }
}

class _TelegramFormattedText extends StatelessWidget {
  const _TelegramFormattedText({required this.text, this.textColor});

  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final segments = _TelegramTextSegment.parse(text);
    if (segments.length == 1 && segments.single.isPlainText) {
      return _TelegramExpandableText(text: text, textColor: textColor);
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

class _TelegramTextSegment {
  const _TelegramTextSegment.text(this.text)
    : language = null,
      quote = false,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;
  const _TelegramTextSegment.quote(this.text)
    : language = null,
      quote = true,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;
  const _TelegramTextSegment.bullets(this.bulletItems)
    : text = '',
      language = null,
      quote = false,
      numberedItems = null,
      startNumber = 1;
  const _TelegramTextSegment.numbered(this.numberedItems, this.startNumber)
    : text = '',
      language = null,
      quote = false,
      bulletItems = null;
  const _TelegramTextSegment.code({required this.text, this.language})
    : quote = false,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;

  static final _codeFencePattern = RegExp(
    r'```([A-Za-z0-9_+.-]*)\n([\s\S]*?)```',
    multiLine: true,
  );

  final String text;
  final String? language;
  final bool quote;
  final List<String>? bulletItems;
  final List<String>? numberedItems;
  final int startNumber;

  bool get isCode => language != null;
  bool get isQuote => quote;
  bool get isBulletList => bulletItems != null;
  bool get isNumberedList => numberedItems != null;
  bool get isPlainText =>
      !isCode && !isQuote && !isBulletList && !isNumberedList;

  static List<_TelegramTextSegment> parse(String text) {
    final segments = <_TelegramTextSegment>[];
    var cursor = 0;
    for (final match in _codeFencePattern.allMatches(text)) {
      _addTextSegments(segments, text.substring(cursor, match.start));
      final language = match.group(1)?.trim();
      final code = match.group(2)?.trimRight() ?? '';
      segments.add(
        _TelegramTextSegment.code(
          text: code,
          language: language == null || language.isEmpty ? 'code' : language,
        ),
      );
      cursor = match.end;
    }
    _addTextSegments(segments, text.substring(cursor));
    return segments.isEmpty ? [_TelegramTextSegment.text(text)] : segments;
  }

  static void _addTextSegments(
    List<_TelegramTextSegment> segments,
    String source,
  ) {
    final lines = source.trim().split('\n');
    final prose = <String>[];
    final quote = <String>[];
    final bullets = <String>[];
    final numberedItems = <String>[];
    int? numberedStart;

    void flushProse() {
      final text = prose.join('\n').trim();
      if (text.isNotEmpty) segments.add(_TelegramTextSegment.text(text));
      prose.clear();
    }

    void flushQuote() {
      final text = quote.join('\n').trim();
      if (text.isNotEmpty) segments.add(_TelegramTextSegment.quote(text));
      quote.clear();
    }

    void flushBullets() {
      if (bullets.isNotEmpty) {
        segments.add(_TelegramTextSegment.bullets(List.unmodifiable(bullets)));
      }
      bullets.clear();
    }

    void flushNumbered() {
      if (numberedItems.isNotEmpty) {
        segments.add(
          _TelegramTextSegment.numbered(
            List.unmodifiable(numberedItems),
            numberedStart ?? 1,
          ),
        );
      }
      numberedItems.clear();
      numberedStart = null;
    }

    for (final line in lines) {
      final trimmed = line.trimRight();
      final numberedMatch = RegExp(
        r'^(\d+)\.\s+(.+)$',
      ).firstMatch(trimmed.trimLeft());
      if (trimmed.trim().isEmpty) {
        flushProse();
        flushQuote();
        flushBullets();
        flushNumbered();
      } else if (trimmed.trimLeft().startsWith('>')) {
        flushProse();
        flushBullets();
        flushNumbered();
        quote.add(trimmed.trimLeft().replaceFirst(RegExp(r'^>\s?'), ''));
      } else if (RegExp(r'^[-*]\s+').hasMatch(trimmed.trimLeft())) {
        flushProse();
        flushQuote();
        flushNumbered();
        bullets.add(trimmed.trimLeft().replaceFirst(RegExp(r'^[-*]\s+'), ''));
      } else if (numberedMatch != null) {
        flushProse();
        flushQuote();
        flushBullets();
        numberedStart ??= int.tryParse(numberedMatch.group(1)!) ?? 1;
        numberedItems.add(numberedMatch.group(2)!);
      } else {
        flushQuote();
        flushBullets();
        flushNumbered();
        prose.add(trimmed);
      }
    }
    flushProse();
    flushQuote();
    flushBullets();
    flushNumbered();
  }
}

class _TelegramBlockquote extends StatelessWidget {
  const _TelegramBlockquote({required this.segment, this.textColor});

  final _TelegramTextSegment segment;
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

  final _TelegramTextSegment segment;
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

  final _TelegramTextSegment segment;
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

  final _TelegramTextSegment segment;
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

  static final _inlinePattern = RegExp(
    r'(\[(@[^:]+):([^\]]+)\]|`[^`]+`|https?:\/\/[^\s<>()]+|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\+?[0-9][0-9 .()-]{6,}[0-9]|\*[^*]+\*|_[^_]+_|~[^~]+~|(?<!\w)[@#][A-Za-z0-9_]+)',
  );

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
    final matches = _inlinePattern.allMatches(text).toList();
    if (matches.isEmpty) return null;
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final raw = _trimTrailingPunctuation(match.group(0)!);
      spans.add(_formattedSpan(raw, Theme.of(context).colorScheme.primary));
      cursor = match.start + raw.length;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return spans;
  }

  String _trimTrailingPunctuation(String raw) {
    if (raw.startsWith('http') || raw.contains('@')) {
      return raw.replaceFirst(RegExp(r'[,.;:!?]+$'), '');
    }
    return raw;
  }

  TextSpan _accentSpan(String text, Color accent) => TextSpan(
    text: text,
    style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w700),
  );

  bool _isDetectionPattern(String raw) =>
      raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.contains('@') ||
      RegExp(r'^\+?[0-9][0-9 .()-]{6,}[0-9]$').hasMatch(raw);

  TextSpan _formattedSpan(String raw, Color accent) {
    final mentionWithId = RegExp(r'^\[(@[^:]+):([^\]]+)\]$').firstMatch(raw);
    if (mentionWithId != null) {
      return _accentSpan(mentionWithId.group(1)!, accent);
    }
    if (_isDetectionPattern(raw)) return _accentSpan(raw, accent);
    final marker = raw.characters.first;
    final inner = marker == '@' || marker == '#'
        ? raw
        : raw.substring(1, raw.length - 1);
    final baseStyle = TextStyle(color: textColor, fontSize: 15);
    return switch (marker) {
      '*' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ),
      '_' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ),
      '`' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: (textColor ?? Colors.black).withValues(alpha: 0.10),
        ),
      ),
      '~' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: textColor,
        ),
      ),
      '@' || '#' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(color: accent, fontWeight: FontWeight.w700),
      ),
      _ => TextSpan(text: raw, style: baseStyle),
    };
  }
}

class _TelegramExpandableText extends StatefulWidget {
  const _TelegramExpandableText({required this.text, this.textColor});

  static const collapsedMaxLines = 8;
  static const collapseCharacterThreshold = 520;
  static const collapseLineThreshold = 8;

  final String text;
  final Color? textColor;

  @override
  State<_TelegramExpandableText> createState() =>
      _TelegramExpandableTextState();
}

class _TelegramExpandableTextState extends State<_TelegramExpandableText> {
  bool _expanded = false;

  bool get _shouldCollapse =>
      widget.text.length > _TelegramExpandableText.collapseCharacterThreshold ||
      '\n'.allMatches(widget.text).length >=
          _TelegramExpandableText.collapseLineThreshold;

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
              ? _TelegramExpandableText.collapsedMaxLines
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

class _TranscriptLinkPreview {
  const _TranscriptLinkPreview({
    required this.url,
    required this.host,
    required this.summary,
  });

  static final _urlPattern = RegExp(
    r'https?:\/\/[^\s<>()]+',
    caseSensitive: false,
  );

  final String url;
  final String host;
  final String summary;

  static _TranscriptLinkPreview? maybeFrom(String text) {
    final match = _urlPattern.firstMatch(text);
    if (match == null) return null;
    final url = match.group(0)!.replaceFirst(RegExp(r'[\],.!?;:]+$'), '');
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final pathAndQuery = [
      if (uri.path.isNotEmpty) uri.path,
      if (uri.query.isNotEmpty) '?${uri.query}',
    ].join();
    return _TranscriptLinkPreview(
      url: url,
      host: uri.host,
      summary: pathAndQuery.isEmpty ? url : pathAndQuery,
    );
  }
}

class _TelegramLinkPreview extends StatelessWidget {
  const _TelegramLinkPreview({required this.linkPreview, this.textColor});

  final _TranscriptLinkPreview linkPreview;
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
