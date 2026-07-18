import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('active header shows agent and gateway and opens sessions', (
    tester,
  ) async {
    await _pumpGatewayChat(tester);

    expect(find.text('AGENT-A'), findsOneWidget);
    expect(find.textContaining('Alpha'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hermes-sessions-panel')), findsOneWidget);
  });

  testWidgets('header selects an older session within the active gateway', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    await harness.channel.createSession(title: 'Current session');
    expect(harness.channel.state.activeSessionId, 'sess_2');

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_1')));
    await tester.pumpAndSettle();

    expect(harness.channel.selectSessionCalls.last, 'sess_1');
    expect(harness.channel.state.activeSessionId, 'sess_1');
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('session list identifies a reply streaming in the background', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background work');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pump(const Duration(milliseconds: 300));

    final row = find.byKey(const ValueKey('hermes-session-row-sess_1'));
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('Streaming reply'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('session list identifies a failed background reply', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('failed work');
    harness.channel.stopActiveTurn();
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('hermes-session-row-sess_1'));
    expect(
      find.descendant(of: row, matching: find.textContaining('Reply failed')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.error_outline)),
      findsOneWidget,
    );
  });

  testWidgets('approval stays attached to its session while switching', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.emitApprovalRequest(
      const HermesApprovalRequest(
        id: 'approval-background',
        toolCallId: 'tool-background',
        prompt: 'Approve background work?',
        runId: 'run-background',
        sessionId: 'sess_1',
      ),
    );
    await tester.pump();
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    expect(find.text('Approve background work?'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_1')));
    await tester.pumpAndSettle();

    expect(find.text('Approve background work?'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-approval-deny')), findsOneWidget);
  });

  testWidgets('sessions are grouped by recent activity', (tester) async {
    final harness = await _pumpGatewayChat(tester);
    final current = DateTime.now();
    final now = DateTime(current.year, current.month, current.day, 12);
    HermesSession session(String id, String title, DateTime lastActive) =>
        HermesSession(
          id: id,
          source: 'test',
          title: title,
          lastActive: lastActive.toIso8601String(),
        );
    harness.channel.replaceSessions([
      session('today', 'Today', now.subtract(const Duration(hours: 1))),
      session('yesterday', 'Yesterday', now.subtract(const Duration(days: 1))),
      session('week', 'This week', now.subtract(const Duration(days: 3))),
      session('earlier', 'Earlier', now.subtract(const Duration(days: 10))),
    ], activeSessionId: 'today');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-session-group-today')), findsOne);
    expect(
      find.byKey(const ValueKey('hermes-session-group-yesterday')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-group-this-week')),
      findsOne,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hermes-session-group-earlier')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('hermes-sessions-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      find.byKey(const ValueKey('hermes-session-group-earlier')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-group-active')),
      findsNothing,
    );
  });

  testWidgets('session rows show source and model metadata', (tester) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.replaceSessions(const [
      HermesSession(
        id: 'metadata',
        source: 'api_server',
        title: 'Metadata session',
        model: 'anthropic/claude-sonnet',
        messageCount: 2,
        lastActive: '2026-07-16T10:30:00Z',
      ),
    ], activeSessionId: 'metadata');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('hermes-session-row-metadata'));
    expect(
      find.descendant(of: row, matching: find.textContaining('api server')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('anthropic/claude-sonnet'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.textContaining('2 messages')),
      findsOneWidget,
    );
    final metadata = tester
        .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
        .map((widget) => widget.data ?? '')
        .firstWhere((text) => text.contains('api server'));
    expect(metadata, contains('Last active'));
    expect(metadata, isNot(contains('2026-07-16T10:30:00Z')));
  });

  testWidgets('phone header keeps secondary actions in overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpGatewayChat(tester);

    expect(find.byKey(const ValueKey('hermes-sessions-button')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
    await tester.pumpAndSettle();
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
  });

  testWidgets('contact tap shows loading feedback before connect finishes', (
    tester,
  ) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      connectGate: () => gate.future,
    );
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'legacy',
          label: 'Legacy',
          baseUrl: 'https://legacy',
        ),
      ],
    );
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader(const {
        'legacy': GatewaySummary(
          profiles: [],
          sessionsByProfile: {},
          unscopedSessions: [],
        ),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('gateway-contact-legacy-default')),
    );
    await tester.pump();

    expect(
      directory.activeContactId,
      const GatewayContactId(gatewayId: 'legacy', profileId: 'default'),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hermes-back-to-contacts')),
      findsOneWidget,
    );
  });

  testWidgets('contact directory exposes adding another gateway', (
    tester,
  ) async {
    await _pumpGatewayChat(tester);

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-connect-another-gateway')),
      findsOneWidget,
    );
  });

  testWidgets('back returns to contacts without deleting gateway', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pumpAndSettle();

    expect(harness.directory.activeContactId, isNull);
    expect(harness.store.deleteProfileCalls, isEmpty);
    expect(find.text('AGENT-A'), findsOneWidget);
    expect(find.text('AGENT-B'), findsOneWidget);
  });

  testWidgets('contact opens when restoring its latest session fails', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.loader.results['a'] = const GatewaySummary(
      profiles: [
        HermesProfile(id: 'agent-a', displayName: 'AGENT-A', revision: 'r'),
      ],
      sessionsByProfile: {
        'agent-a': [HermesSession(id: 'sess_1', source: 'test')],
      },
    );
    await harness.directory.refresh();
    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pumpAndSettle();
    harness.channel.selectSessionFails = true;

    await tester.tap(find.byKey(const ValueKey('gateway-contact-a-agent-a')));
    await tester.pumpAndSettle();

    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
    expect(
      find.byKey(const ValueKey('hermes-back-to-contacts')),
      findsOneWidget,
    );
  });

  testWidgets('system back returns to contacts without deleting gateway', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(harness.directory.activeContactId, isNull);
    expect(harness.store.deleteProfileCalls, isEmpty);
    expect(find.text('AGENT-A'), findsOneWidget);
    expect(find.text('AGENT-B'), findsOneWidget);
  });

  testWidgets('system back preserves the active-work switch guard', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('work');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('background reply preserves the gateway switch guard', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background work');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('disconnect removes only the active gateway', (tester) async {
    final harness = await _pumpGatewayChat(tester);

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Other saved Hermes gateways'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-confirm')));
    await tester.pumpAndSettle();

    expect(harness.store.deleteProfileCalls, ['a']);
    expect(find.text('AGENT-A'), findsNothing);
    expect(find.text('AGENT-B'), findsOneWidget);
  });

  testWidgets('resume fully reconnects the active contact only', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(harness.channel.connectCalls, hasLength(2));
    expect(harness.channel.disconnectCalls, 1);
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('resume preserves an attached live stream', (tester) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('keep streaming');
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 500));

    expect(harness.channel.connectCalls, hasLength(1));
    expect(harness.channel.disconnectCalls, 0);
    expect(harness.channel.state.hasStreamingSessions, isTrue);
  });

  testWidgets('completed turn refreshes active contact summary', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);

    await harness.channel.sendText('hello');
    await tester.pumpAndSettle();

    expect(harness.channel.state.activeMessages, hasLength(2));
    expect(harness.loader.calls.where((id) => id == 'a'), hasLength(2));
    expect(harness.loader.calls.where((id) => id == 'b'), hasLength(1));
  });

  testWidgets('background completion refreshes the gateway summary', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('background summary');
    await harness.channel.createSession(title: 'Foreground');
    await tester.pump();
    final callsBeforeCompletion = harness.loader.calls
        .where((id) => id == 'a')
        .length;

    harness.channel.completeStreamingTurn(
      text: 'background done',
      sessionId: 'sess_1',
    );
    await tester.pump();

    expect(
      harness.loader.calls.where((id) => id == 'a'),
      hasLength(callsBeforeCompletion + 1),
    );
  });

  testWidgets('pending approval requires confirmation before leaving contact', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.emitApprovalRequest(
      const HermesApprovalRequest(
        id: 'approval-1',
        toolCallId: 'tool-1',
        prompt: 'Run a command?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('in-flight submission requires confirmation before leaving', (
    tester,
  ) async {
    final gate = Completer<void>();
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      sendTextGate: () => gate.future,
    );
    final harness = await _pumpGatewayChat(tester, channel: channel);

    unawaited(harness.channel.sendText('work'));
    await tester.pump();
    expect(
      harness.channel.state.activeMessages.last.status,
      HermesTurnStatus.streaming,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });

  testWidgets('active run requires confirmation before leaving contact', (
    tester,
  ) async {
    final harness = await _pumpGatewayChat(tester);
    harness.channel.beginStreamingTurn('work');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(
      harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
    );
  });
}

Future<
  ({
    HermesGatewayDirectory directory,
    FakeHermesChannel channel,
    FakeHermesEndpointStore store,
    FakeGatewaySummaryLoader loader,
  })
>
_pumpGatewayChat(WidgetTester tester, {FakeHermesChannel? channel}) async {
  channel ??= FakeHermesChannel.disconnected();
  final store = FakeHermesEndpointStore(
    profiles: const [
      HermesEndpointConfig(
        id: 'a',
        label: 'Alpha',
        baseUrl: 'https://a',
        apiKey: 'a-secret',
      ),
      HermesEndpointConfig(
        id: 'b',
        label: 'Beta',
        baseUrl: 'https://b',
        apiKey: 'b-secret',
      ),
    ],
  );
  final loader = FakeGatewaySummaryLoader({
    'a': gatewaySummary(['agent-a']),
    'b': gatewaySummary(['agent-b']),
  });
  final directory = HermesGatewayDirectory(
    store: store,
    cache: FakeGatewayContactCache(),
    loader: loader,
    activeChannel: channel,
  );
  await directory.refresh();
  await directory.activate(
    const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (directory: directory, channel: channel, store: store, loader: loader);
}
