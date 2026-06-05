enum TranscriptTextSegmentKind { text, quote, bulletList, numberedList, code }

enum TranscriptInlineTokenKind {
  plain,
  bold,
  italic,
  code,
  strike,
  accent,
  detected,
}

class TranscriptTextContentPresentation {
  const TranscriptTextContentPresentation({
    required this.text,
    required this.segments,
    required this.linkPreview,
  });

  factory TranscriptTextContentPresentation.fromText(String text) {
    return TranscriptTextContentPresentation(
      text: text,
      segments: TranscriptTextSegment.parse(text),
      linkPreview: TranscriptLinkPreviewPresentation.maybeFrom(text),
    );
  }

  final String text;
  final List<TranscriptTextSegment> segments;
  final TranscriptLinkPreviewPresentation? linkPreview;

  bool get isSinglePlainTextSegment =>
      segments.length == 1 && segments.single.isPlainText;
}

class TranscriptTextSegment {
  const TranscriptTextSegment.text(this.text)
    : kind = TranscriptTextSegmentKind.text,
      language = null,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;
  const TranscriptTextSegment.quote(this.text)
    : kind = TranscriptTextSegmentKind.quote,
      language = null,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;
  const TranscriptTextSegment.bullets(this.bulletItems)
    : kind = TranscriptTextSegmentKind.bulletList,
      text = '',
      language = null,
      numberedItems = null,
      startNumber = 1;
  const TranscriptTextSegment.numbered(this.numberedItems, this.startNumber)
    : kind = TranscriptTextSegmentKind.numberedList,
      text = '',
      language = null,
      bulletItems = null;
  const TranscriptTextSegment.code({required this.text, this.language})
    : kind = TranscriptTextSegmentKind.code,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;

  static final _codeFencePattern = RegExp(
    r'```([A-Za-z0-9_+.-]*)\n([\s\S]*?)```',
    multiLine: true,
  );

  final TranscriptTextSegmentKind kind;
  final String text;
  final String? language;
  final List<String>? bulletItems;
  final List<String>? numberedItems;
  final int startNumber;

  bool get isCode => kind == TranscriptTextSegmentKind.code;
  bool get isQuote => kind == TranscriptTextSegmentKind.quote;
  bool get isBulletList => kind == TranscriptTextSegmentKind.bulletList;
  bool get isNumberedList => kind == TranscriptTextSegmentKind.numberedList;
  bool get isPlainText => kind == TranscriptTextSegmentKind.text;

  static List<TranscriptTextSegment> parse(String text) {
    final segments = <TranscriptTextSegment>[];
    var cursor = 0;
    for (final match in _codeFencePattern.allMatches(text)) {
      _addTextSegments(segments, text.substring(cursor, match.start));
      final language = match.group(1)?.trim();
      final code = match.group(2)?.trimRight() ?? '';
      segments.add(
        TranscriptTextSegment.code(
          text: code,
          language: language == null || language.isEmpty ? 'code' : language,
        ),
      );
      cursor = match.end;
    }
    _addTextSegments(segments, text.substring(cursor));
    return segments.isEmpty ? [TranscriptTextSegment.text(text)] : segments;
  }

  static void _addTextSegments(
    List<TranscriptTextSegment> segments,
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
      if (text.isNotEmpty) segments.add(TranscriptTextSegment.text(text));
      prose.clear();
    }

    void flushQuote() {
      final text = quote.join('\n').trim();
      if (text.isNotEmpty) segments.add(TranscriptTextSegment.quote(text));
      quote.clear();
    }

    void flushBullets() {
      if (bullets.isNotEmpty) {
        segments.add(TranscriptTextSegment.bullets(List.unmodifiable(bullets)));
      }
      bullets.clear();
    }

    void flushNumbered() {
      if (numberedItems.isNotEmpty) {
        segments.add(
          TranscriptTextSegment.numbered(
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

class TranscriptInlineToken {
  const TranscriptInlineToken({required this.text, required this.kind});

  static final _inlinePattern = RegExp(
    r'(\[(@[^:]+):([^\]]+)\]|`[^`]+`|https?:\/\/[^\s<>()]+|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\+?[0-9][0-9 .()-]{6,}[0-9]|\*[^*]+\*|_[^_]+_|~[^~]+~|(?<!\w)[@#][A-Za-z0-9_]+)',
  );

  final String text;
  final TranscriptInlineTokenKind kind;

  static List<TranscriptInlineToken> parse(String text) {
    final matches = _inlinePattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return [
        TranscriptInlineToken(
          text: text,
          kind: TranscriptInlineTokenKind.plain,
        ),
      ];
    }
    final tokens = <TranscriptInlineToken>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        tokens.add(
          TranscriptInlineToken(
            text: text.substring(cursor, match.start),
            kind: TranscriptInlineTokenKind.plain,
          ),
        );
      }
      final raw = _trimTrailingPunctuation(match.group(0)!);
      tokens.add(_formattedToken(raw));
      cursor = match.start + raw.length;
    }
    if (cursor < text.length) {
      tokens.add(
        TranscriptInlineToken(
          text: text.substring(cursor),
          kind: TranscriptInlineTokenKind.plain,
        ),
      );
    }
    return tokens;
  }

  static String _trimTrailingPunctuation(String raw) {
    if (raw.startsWith('http') || raw.contains('@')) {
      return raw.replaceFirst(RegExp(r'[,.;:!?]+$'), '');
    }
    return raw;
  }

  static bool _isDetectionPattern(String raw) =>
      raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.contains('@') ||
      RegExp(r'^\+?[0-9][0-9 .()-]{6,}[0-9]$').hasMatch(raw);

  static TranscriptInlineToken _formattedToken(String raw) {
    final mentionWithId = RegExp(r'^\[(@[^:]+):([^\]]+)\]$').firstMatch(raw);
    if (mentionWithId != null) {
      return TranscriptInlineToken(
        text: mentionWithId.group(1)!,
        kind: TranscriptInlineTokenKind.accent,
      );
    }
    if (_isDetectionPattern(raw)) {
      return TranscriptInlineToken(
        text: raw,
        kind: TranscriptInlineTokenKind.detected,
      );
    }
    final marker = raw[0];
    final inner = marker == '@' || marker == '#'
        ? raw
        : raw.substring(1, raw.length - 1);
    final kind = switch (marker) {
      '*' => TranscriptInlineTokenKind.bold,
      '_' => TranscriptInlineTokenKind.italic,
      '`' => TranscriptInlineTokenKind.code,
      '~' => TranscriptInlineTokenKind.strike,
      '@' || '#' => TranscriptInlineTokenKind.accent,
      _ => TranscriptInlineTokenKind.plain,
    };
    return TranscriptInlineToken(text: inner, kind: kind);
  }
}

class TranscriptTextCollapsePolicy {
  const TranscriptTextCollapsePolicy._();

  static const collapsedMaxLines = 8;
  static const collapseCharacterThreshold = 520;
  static const collapseLineThreshold = 8;

  static bool shouldCollapse(String text) {
    return text.length > collapseCharacterThreshold ||
        '\n'.allMatches(text).length >= collapseLineThreshold;
  }
}

class TranscriptLinkPreviewPresentation {
  const TranscriptLinkPreviewPresentation({
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

  static TranscriptLinkPreviewPresentation? maybeFrom(String text) {
    final match = _urlPattern.firstMatch(text);
    if (match == null) return null;
    final url = match.group(0)!.replaceFirst(RegExp(r'[\],.!?;:]+$'), '');
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final pathAndQuery = [
      if (uri.path.isNotEmpty) uri.path,
      if (uri.query.isNotEmpty) '?${uri.query}',
    ].join();
    return TranscriptLinkPreviewPresentation(
      url: url,
      host: uri.host,
      summary: pathAndQuery.isEmpty ? url : pathAndQuery,
    );
  }
}
