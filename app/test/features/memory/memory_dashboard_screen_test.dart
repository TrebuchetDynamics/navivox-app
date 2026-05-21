import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';
import 'package:navivox/features/memory/screens/memory_dashboard_screen.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  testWidgets(
    'memory dashboard shows profile-scoped Goncho counts with a safe database label',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(const [
          NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
        ], activeServerId: 'local')
        ..seedProfileContacts(const [
          NavivoxProfileContact(
            serverId: 'local',
            profileId: 'mineru',
            displayName: 'Mineru Builder',
            serverLabel: 'local',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Goncho memory active',
          ),
        ], selectedKey: 'local::mineru')
        ..seedMemoryOverview(
          NavivoxMemoryOverview(
            profileId: 'mineru',
            workspaceId: 'gormes',
            databaseLabel: '~/.gormes/profiles/mineru/memory.db',
            health: NavivoxMemoryHealth.active,
            totalTurns: 120,
            activeMemoryItems: 12,
            observations: 34,
            conclusions: 5,
            sessionSummaries: 7,
            entities: 18,
            relationships: 21,
            lastUpdatedAt: DateTime.utc(2026, 5, 21, 15, 28, 18),
          ),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(home: MemoryDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Memory'), findsWidgets);
      expect(find.text('Goncho active'), findsOneWidget);
      expect(find.text('Profile: Mineru Builder'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('Turns'), findsWidgets);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Active memory items'), findsOneWidget);
      expect(find.text('~/.gormes/profiles/mineru/memory.db'), findsOneWidget);
      expect(find.textContaining('/home/xel'), findsNothing);
    },
  );

  testWidgets('memory dashboard includes searchable browse cards', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Goncho memory active',
        ),
      ], selectedKey: 'local::mineru')
      ..seedMemoryOverview(
        const NavivoxMemoryOverview(
          profileId: 'mineru',
          workspaceId: 'gormes',
          databaseLabel: '~/.gormes/profiles/mineru/memory.db',
          health: NavivoxMemoryHealth.active,
          totalTurns: 2,
          activeMemoryItems: 1,
          observations: 0,
          conclusions: 1,
          sessionSummaries: 0,
          entities: 0,
          relationships: 0,
        ),
      )
      ..seedMemorySearch(
        const NavivoxMemorySearchResult(
          items: [
            NavivoxMemoryItem(
              id: 'mem-1',
              type: NavivoxMemoryType.memoryItems,
              snippet: 'Mineru uses Goncho memory for workspace recall.',
              timestamp: '2026-05-21T15:30:00Z',
              sessionId: 's-1',
              peerId: 'mineru',
              status: 'current',
              tags: ['workspace', 'recall'],
              score: 0.92,
            ),
            NavivoxMemoryItem(
              id: 'conclusion-1',
              type: NavivoxMemoryType.conclusions,
              snippet: 'Juan prefers exact evidence before claims.',
              timestamp: '2026-05-21T15:31:00Z',
              sessionId: 's-2',
              peerId: 'juan',
              status: 'processed',
            ),
          ],
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: MemoryDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search & Browse'), findsOneWidget);
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    expect(find.text('Memory items'), findsOneWidget);
    expect(find.text('Conclusions'), findsWidgets);
    expect(
      find.text('Mineru uses Goncho memory for workspace recall.'),
      findsOneWidget,
    );
    expect(find.text('memory_items · current · s-1 · mineru'), findsOneWidget);
    expect(find.text('workspace'), findsOneWidget);
    expect(find.text('recall'), findsOneWidget);

    await tester.enterText(searchField, 'Goncho');
    await tester.pumpAndSettle();

    expect(channel.memorySearchCalls.last.query, 'Goncho');
    expect(channel.memorySearchCalls.last.profileId, 'mineru');
  });

  testWidgets('memory dashboard reports degraded API state safely', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.warning,
          latestPreview: 'Memory API unavailable',
        ),
      ], selectedKey: 'local::mineru')
      ..seedMemoryOverview(
        const NavivoxMemoryOverview.degraded(
          profileId: 'mineru',
          reason: 'Gormes memory API is unavailable.',
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: MemoryDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Goncho degraded'), findsOneWidget);
    expect(find.text('Gormes memory API is unavailable.'), findsOneWidget);
    expect(find.text('Profile: Mineru Builder'), findsOneWidget);
  });
}
