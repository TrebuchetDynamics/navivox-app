import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

Widget _testApp(FakeHermesChannel channel, {double textScale = 1}) =>
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    );

void main() {
  testWidgets('slash suggestions execute the local new-session command', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/n',
    );
    await tester.pump();

    expect(find.text('Wing commands'), findsOneWidget);
    expect(find.text('/new'), findsOneWidget);
    expect(find.text('/sessions'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-local-command-new')));
    await tester.pumpAndSettle();

    expect(channel.createSessionCalls, [null]);
    expect(channel.sentVoiceTranscripts, isEmpty);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('slash suggestions remain usable at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/s',
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('/sessions'), findsOneWidget);
    expect(find.text('/settings'), findsOneWidget);
    expect(find.text('/new'), findsNothing);
  });

  testWidgets('exact local clear command never reaches Hermes', (tester) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/clear',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, isEmpty);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('local commands cannot bypass an active run', (tester) async {
    final channel = FakeHermesChannel()..beginStreamingTurn('Running work');
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/new',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(channel.createSessionCalls, isEmpty);
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
  });

  testWidgets('unknown slash commands remain server-owned messages', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/retry',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(
      channel.state.activeMessages.any((turn) => turn.text == '/retry'),
      isTrue,
    );
  });
}
