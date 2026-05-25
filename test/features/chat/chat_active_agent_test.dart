import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';

import '../../support/test_navivox_channel.dart';

const _seedAgents = [
  NavivoxAgent(id: 'def', name: 'Default', status: 'ready'),
  NavivoxAgent(id: 'arch', name: 'Architect', status: 'ready'),
];

const _seedServers = [
  NavivoxServer(id: 'srv1', name: 'Local', status: 'ready'),
];

const _seedProfiles = [
  NavivoxProfileContact(
    serverId: 'srv1',
    profileId: 'mineru',
    displayName: 'Mineru Builder',
    serverLabel: 'Local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready for scoped chat',
  ),
];

void main() {
  testWidgets(
    'chat AppBar omits the active-agent indicator when no agent is selected',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(_seedServers, activeServerId: 'srv1')
        ..seedAgents(_seedAgents);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      expect(find.byKey(const ValueKey('chat-active-agent')), findsNothing);
    },
  );

  testWidgets('chat AppBar keeps agent context behind a compact info action', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_seedServers, activeServerId: 'srv1')
      ..seedAgents(_seedAgents, selectedAgentId: 'arch');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );

    expect(find.byKey(const ValueKey('chat-active-agent')), findsNothing);
    expect(find.byKey(const ValueKey('chat-context-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chat-context-action')));
    await tester.pumpAndSettle();

    expect(find.text('Chat info'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Architect'), findsOneWidget);
  });

  testWidgets('chat AppBar shows active profile avatar like Telegram header', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_seedServers, activeServerId: 'srv1')
      ..seedProfileContacts(_seedProfiles, selectedKey: 'srv1::mineru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );

    expect(
      find.byKey(const ValueKey('chat-active-profile-avatar')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('chat-active-profile-avatar')),
        matching: find.text('M'),
      ),
      findsOneWidget,
    );
    expect(find.text('Mineru Builder'), findsOneWidget);
  });

  testWidgets('chat info exposes active server and profile scope', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_seedServers, activeServerId: 'srv1')
      ..seedProfileContacts(_seedProfiles, selectedKey: 'srv1::mineru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('chat-context-action')));
    await tester.pumpAndSettle();

    expect(find.text('Chat info'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Profile ID'), findsOneWidget);
    expect(find.text('mineru'), findsOneWidget);
    expect(find.text('Server ID'), findsOneWidget);
    expect(find.text('srv1'), findsOneWidget);
  });
}
