import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/hermes_rich_text.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

Widget _localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets(
    'assistant markdown renders without exposing formatting markers',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.beginStreamingTurn('Format this response.');
      channel.completeStreamingTurn(text: '**Strong answer**');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: _localizedApp(const HermesChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('**Strong answer**'), findsNothing);
      expect(find.text('Strong answer', findRichText: true), findsOneWidget);
    },
  );

  testWidgets('short conversations stay anchored above the composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer');
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final bubbleBottom = tester
        .getBottomLeft(find.byKey(ValueKey('hermes-turn-$assistantId')))
        .dy;
    final composerTop = tester
        .getTopLeft(find.byKey(const ValueKey('hermes-composer-surface')))
        .dy;
    expect(composerTop - bubbleBottom, lessThan(48));
  });

  testWidgets('message bubbles keep Telegram-style bottom tails', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer');
    final userId = channel.state.activeMessages.first.id;
    final assistantId = channel.state.activeMessages.last.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    BoxDecoration decoration(String id) =>
        tester
                .widget<Container>(find.byKey(ValueKey('hermes-turn-$id')))
                .decoration
            as BoxDecoration;
    final userRadius = decoration(userId).borderRadius! as BorderRadius;
    final assistantRadius =
        decoration(assistantId).borderRadius! as BorderRadius;
    expect(userRadius.bottomRight, const Radius.circular(5));
    expect(userRadius.topRight, const Radius.circular(16));
    expect(assistantRadius.bottomLeft, const Radius.circular(5));
    expect(assistantRadius.topLeft, const Radius.circular(16));
  });

  testWidgets('long press offers copy and reply actions', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Question');
    channel.completeStreamingTurn(text: 'Answer to reuse');
    final assistantId = channel.state.activeMessages.last.id;
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final bubble = find.byKey(ValueKey('hermes-turn-$assistantId'));
    await tester.longPress(bubble);
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copiedText, 'Answer to reuse');

    await tester.longPress(bubble);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(composer.controller?.text, '> Answer to reuse\n\n');
  });

  testWidgets(
    'empty completed assistant turns do not render timestamp bubbles',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.beginStreamingTurn('Do not leave an empty bubble.');
      channel.completeStreamingTurn(text: '');
      final emptyTurnId = channel.state.activeMessages.last.id;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: _localizedApp(const HermesChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('hermes-turn-$emptyTurnId')), findsNothing);
    },
  );

  testWidgets('structured assistant errors render as readable messages', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Run it.');
    channel.completeStreamingTurn(
      text:
          '{"status":"error","error":"BLOCKED: execution needs approval. Do not retry the command until approval is available. The requested action was not run and no external state changed. Choose another approach or review the request details.","tool_calls_made":0}',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-structured-assistant-error')),
      findsOneWidget,
    );
    expect(find.text('Action blocked'), findsOneWidget);
    expect(find.textContaining('execution needs approval'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.textContaining('tool_calls_made'), findsNothing);

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('Hide details'), findsOneWidget);
  });

  testWidgets('assistant prose remains visible to accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _localizedApp(const Scaffold(body: HermesRichText('Accessible answer'))),
    );

    expect(find.bySemanticsLabel('Accessible answer'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('assistant code blocks can be copied', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Show the code.');
    channel.completeStreamingTurn(text: '```dart\nfinal answer = 42;\n```');
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-code-copy')));
    await tester.pump();

    expect(copiedText, 'final answer = 42;');
  });

  testWidgets('long code blocks start collapsed and can be expanded', (
    tester,
  ) async {
    final code = List.generate(16, (index) => 'line ${index + 1}').join('\n');

    await tester.pumpWidget(
      _localizedApp(Scaffold(body: HermesRichText('```text\n$code\n```'))),
    );

    expect(find.text('Show more'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-code-content')), findsNothing);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-code-content')), findsOneWidget);
  });

  testWidgets('diff code blocks distinguish additions removals and hunks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        const Scaffold(
          body: HermesRichText(
            '```diff\n+added\n-removed\n@@ changed @@\n unchanged\n```',
          ),
        ),
      ),
    );

    final colors = Theme.of(
      tester.element(find.byType(HermesRichText)),
    ).colorScheme;
    expect(find.text('diff'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('hermes-diff-line-0')),
          )
          .style
          ?.color,
      colors.onTertiaryContainer,
    );
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('hermes-diff-line-1')),
          )
          .style
          ?.color,
      colors.onErrorContainer,
    );
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('hermes-diff-line-2')),
          )
          .style
          ?.color,
      colors.onSecondaryContainer,
    );
  });

  testWidgets('remote transcript images stay deferred', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Show the diagram.');
    channel.completeStreamingTurn(
      text: '![Architecture diagram](https://example.com/private.png)',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(
      find.text('Architecture diagram (image not loaded)'),
      findsOneWidget,
    );
  });

  testWidgets('safe transcript links use the external launcher', (
    tester,
  ) async {
    Uri? launchedUri;

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: HermesRichText(
            '[Open docs](https://example.com/docs)',
            launchUri: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open docs', findRichText: true));
    await tester.pump();

    expect(launchedUri, Uri.parse('https://example.com/docs'));
  });

  testWidgets('unsafe transcript link schemes stay inert', (tester) async {
    var launchCount = 0;

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: HermesRichText(
            '[Do not run](javascript:alert(1))',
            launchUri: (uri) async {
              launchCount++;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Do not run', findRichText: true));
    await tester.pump();

    expect(launchCount, 0);
  });
}
