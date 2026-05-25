import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';
import 'package:navivox/router/app_router.dart';

import '../../support/test_navivox_channel.dart';

const _servers = [
  NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
  NavivoxServer(id: 'office', name: 'Office', status: 'offline'),
];

final _contacts = [
  NavivoxProfileContact(
    serverId: 'local',
    profileId: 'mineru',
    displayName: 'Mineru Builder',
    serverLabel: 'local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready to work on mineru',
    latestAt: DateTime(2026, 5, 16, 9, 41),
    workspaceRootCount: 2,
    micAvailable: true,
  ),
  NavivoxProfileContact(
    serverId: 'office',
    profileId: 'support',
    displayName: 'Support Triage',
    serverLabel: 'office',
    health: NavivoxProfileHealth.needsAuth,
    latestPreview: 'Waiting for token',
    latestAt: DateTime(2026, 5, 16, 9, 22),
    workspaceRootCount: 1,
    attentionBadges: ['auth'],
    micAvailable: false,
  ),
  NavivoxProfileContact(
    serverId: 'local',
    profileId: 'personal',
    displayName: 'Personal',
    serverLabel: 'local',
    health: NavivoxProfileHealth.offline,
    latestPreview: 'Gateway unavailable',
    latestAt: DateTime(2026, 5, 15, 18),
    workspaceRootCount: 0,
    attentionBadges: ['offline'],
    micAvailable: false,
  ),
];

void main() {
  testWidgets('renders profiles as a flat multi-server contact list', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Navivox'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsOneWidget);
    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-contact-local-mineru')),
      findsOneWidget,
    );
    expect(find.text('local'), findsWidgets);
    expect(find.text('office'), findsOneWidget);
    expect(find.text('2 roots'), findsOneWidget);
    expect(find.text('auth'), findsWidgets);
    expect(find.byKey(const ValueKey('profile-attention-office-support')), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('May 16'), findsWidgets);
    expect(find.text('May 15'), findsOneWidget);
    expect(find.byTooltip('Add profile'), findsOneWidget);
  });

  testWidgets('server filter chips narrow contacts by gateway', (tester) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('server-filter-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('server-filter-local')), findsOneWidget);
    expect(find.byKey(const ValueKey('server-filter-office')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-filter-office')));
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
    expect(find.text('Personal'), findsNothing);
    expect(find.text('1 profile'), findsOneWidget);
  });

  testWidgets('search filters profile contacts like Telegram chat search', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search profiles'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('profile-search-field')),
      'support',
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
    expect(find.text('Personal'), findsNothing);
  });

  testWidgets('search matches profile health and capability diagnostics', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search profiles'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-search-field')),
      'auth required',
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
    expect(find.text('Personal'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('profile-search-field')),
      'mic unavailable',
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
  });

  testWidgets('search shows a no results state', (tester) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search profiles'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-search-field')),
      'missing',
    );
    await tester.pumpAndSettle();

    expect(find.text('No chats found'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
  });

  testWidgets('streaming profile contact shows Telegram-like typing state', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts([
        NavivoxProfileContact(
          serverId: _contacts.first.serverId,
          profileId: _contacts.first.profileId,
          displayName: _contacts.first.displayName,
          serverLabel: _contacts.first.serverLabel,
          health: _contacts.first.health,
          latestPreview: _contacts.first.latestPreview,
          latestAt: _contacts.first.latestAt,
          workspaceRootCount: _contacts.first.workspaceRootCount,
          micAvailable: _contacts.first.micAvailable,
          activeTurnState: 'streaming',
        ),
        ..._contacts.skip(1),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('typing…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-active-turn-local-mineru')),
      findsOneWidget,
    );
  });

  testWidgets('selecting a profile opens scoped chat and sends in that scope', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-contact-office-support')),
    );
    await tester.pumpAndSettle();

    expect(channel.selectedProfileScope, (
      serverId: 'office',
      profileId: 'support',
    ));
    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-active-profile')), findsNothing);
    expect(find.byKey(const ValueKey('chat-context-action')), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'triage latest ticket',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(channel.sentTexts, ['triage latest ticket']);
    expect(channel.sentTextCalls.last, (
      text: 'triage latest ticket',
      serverId: 'office',
      profileId: 'support',
    ));
  });

  testWidgets('selecting a profile encodes chat route path segments', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'office team', name: 'Office Team', status: 'online'),
      ], activeServerId: 'office team')
      ..seedProfileContacts([
        NavivoxProfileContact(
          serverId: 'office team',
          profileId: 'support/desk',
          displayName: 'Support Escalation',
          serverLabel: 'office team',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Watching escalations',
          latestAt: DateTime(2026, 5, 16, 10, 12),
          workspaceRootCount: 1,
          micAvailable: true,
        ),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-contact-office team-support/desk')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Route not found'), findsNothing);
    expect(channel.selectedProfileScope, (
      serverId: 'office team',
      profileId: 'support/desk',
    ));
    expect(find.text('Support Escalation'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'triage escalation',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(channel.sentTextCalls.last, (
      text: 'triage escalation',
      serverId: 'office team',
      profileId: 'support/desk',
    ));
  });

  testWidgets('chat back button returns to profile contacts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-contact-office-support')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Navivox'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-contact-local-mineru')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-contact-office-support')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
  });

  testWidgets('long pressing a profile opens diagnostics and scoped actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(
      find.byKey(const ValueKey('profile-contact-local-mineru')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile details'), findsOneWidget);
    expect(find.text('Mineru Builder\nmineru'), findsOneWidget);
    expect(find.text('Profile diagnostics'), findsOneWidget);
    expect(find.text('Health: online'), findsOneWidget);
    expect(find.text('Workspace: 2 roots'), findsOneWidget);
    expect(find.text('Voice: mic available'), findsOneWidget);
    expect(find.text('Latest: Ready to work on mineru'), findsOneWidget);
    expect(find.text('Identity / system prompt'), findsOneWidget);
    expect(find.text('Profile path: mineru'), findsOneWidget);
    expect(find.text('Connected channels'), findsOneWidget);
    expect(find.text('Local/web chat: enabled'), findsOneWidget);
    expect(find.text('Memory settings'), findsOneWidget);
    expect(find.text('Goncho status: available'), findsOneWidget);
    expect(find.text('Skills list'), findsOneWidget);
    expect(find.text('Skills: not reported by API'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Config/environment summary'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Config/environment summary'), findsOneWidget);
    expect(find.text('Config: profile scoped'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Logs/status'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Logs/status'), findsOneWidget);
    expect(find.text('Status: online'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open chat'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Open chat'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open memory'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Open memory'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);

    await tester.tap(find.text('Open memory'));
    await tester.pumpAndSettle();

    expect(channel.selectedProfileScope, (
      serverId: 'local',
      profileId: 'mineru',
    ));
    expect(find.text('Memory'), findsWidgets);
    expect(find.text('Profile: Mineru Builder'), findsOneWidget);
  });

  testWidgets('deep-linked chat route selects the profile scope', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(_servers, activeServerId: 'local')
      ..seedProfileContacts(_contacts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          home: ChatScreen(serverId: 'office', profileId: 'support'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(channel.selectedProfileScope, (
      serverId: 'office',
      profileId: 'support',
    ));
    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-active-profile')), findsNothing);
    expect(find.byKey(const ValueKey('chat-context-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chat-context-action')));
    await tester.pumpAndSettle();

    expect(find.text('Chat info'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Support Triage'), findsWidgets);
    expect(find.text('office'), findsOneWidget);
  });
}

class _RouterTestApp extends ConsumerWidget {
  const _RouterTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
