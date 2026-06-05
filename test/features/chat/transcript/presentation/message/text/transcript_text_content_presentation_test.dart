import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/transcript/presentation/message/text/transcript_text_content_presentation.dart';

void main() {
  test('segments prose, quote, lists, and fenced code', () {
    final presentation = TranscriptTextContentPresentation.fromText('''
Intro paragraph
> quoted line
- one
- two
3. third
4. fourth
```dart
void main() {}
```
''');

    expect(presentation.segments.map((segment) => segment.kind), [
      TranscriptTextSegmentKind.text,
      TranscriptTextSegmentKind.quote,
      TranscriptTextSegmentKind.bulletList,
      TranscriptTextSegmentKind.numberedList,
      TranscriptTextSegmentKind.code,
    ]);
    expect(presentation.segments[0].text, 'Intro paragraph');
    expect(presentation.segments[1].text, 'quoted line');
    expect(presentation.segments[2].bulletItems, ['one', 'two']);
    expect(presentation.segments[3].numberedItems, ['third', 'fourth']);
    expect(presentation.segments[3].startNumber, 3);
    expect(presentation.segments[4].language, 'dart');
    expect(presentation.segments[4].text, 'void main() {}');
  });

  test('normalizes unlabeled fenced code as code', () {
    final segments = TranscriptTextSegment.parse('''```
plain
```''');

    expect(segments.single.kind, TranscriptTextSegmentKind.code);
    expect(segments.single.language, 'code');
    expect(segments.single.text, 'plain');
  });

  test('extracts link preview without trailing punctuation', () {
    final preview = TranscriptLinkPreviewPresentation.maybeFrom(
      'See https://example.test/path?q=one.',
    );

    expect(preview, isNotNull);
    expect(preview!.url, 'https://example.test/path?q=one');
    expect(preview.host, 'example.test');
    expect(preview.summary, '/path?q=one');
  });

  test('classifies inline markers and detected references', () {
    final tokens = TranscriptInlineToken.parse(
      'Hi *bold* _it_ `code` ~no~ @tag #topic [@Mineru:profile_mineru] https://example.test.',
    );

    expect(
      tokens
          .map((token) => token.kind)
          .where((kind) => kind != TranscriptInlineTokenKind.plain),
      [
        TranscriptInlineTokenKind.bold,
        TranscriptInlineTokenKind.italic,
        TranscriptInlineTokenKind.code,
        TranscriptInlineTokenKind.strike,
        TranscriptInlineTokenKind.detected,
        TranscriptInlineTokenKind.accent,
        TranscriptInlineTokenKind.accent,
        TranscriptInlineTokenKind.detected,
      ],
    );
    expect(tokens.map((token) => token.text), contains('@Mineru'));
    expect(tokens.map((token) => token.text), contains('https://example.test'));
  });

  test('keeps expandability policy out of the widget', () {
    expect(TranscriptTextCollapsePolicy.shouldCollapse('short'), isFalse);
    expect(
      TranscriptTextCollapsePolicy.shouldCollapse(
        List.filled(9, 'x').join('\n'),
      ),
      isTrue,
    );
    expect(TranscriptTextCollapsePolicy.shouldCollapse('x' * 521), isTrue);
  });
}
