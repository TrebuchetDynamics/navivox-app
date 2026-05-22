import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/settings/screens/settings_screen.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  testWidgets('renders continuous voice controls for the active server', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Voice settings'), findsOneWidget);
    expect(find.text('Continuous voice'), findsOneWidget);
    expect(find.text('Command word'), findsOneWidget);
    expect(find.text('navi'), findsOneWidget);

    final trustSwitch = find.byKey(const ValueKey('voice-trust-local'));
    expect(tester.widget<SwitchListTile>(trustSwitch).value, isFalse);

    await tester.tap(trustSwitch);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(trustSwitch).value, isTrue);
  });

  testWidgets('settings explain global scope and link to management tabs', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Global app settings'), findsOneWidget);
    expect(
      find.text(
        'Voice controls stay local to this app. Gateway and profile settings live in their own screens.',
      ),
      findsOneWidget,
    );
    expect(find.text('Manage gateways'), findsOneWidget);
    expect(find.text('Manage profile contacts'), findsOneWidget);

    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('settings-manage-gateways')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('settings-manage-profiles')),
          )
          .onTap,
      isNotNull,
    );
  });

  testWidgets('settings expose the active gateway and profile scope', (
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
          latestPreview: 'Ready',
        ),
      ], selectedKey: 'local::mineru');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.scrollUntilVisible(find.text('Current session scope'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Current session scope'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-current-gateway')),
      findsOneWidget,
    );
    expect(find.text('Active Gormes gateway'), findsOneWidget);
    expect(find.text('Local Gormes · local'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-current-profile')),
      findsOneWidget,
    );
    expect(find.text('Active profile contact'), findsOneWidget);
    expect(find.text('Mineru Builder · local/mineru'), findsOneWidget);
  });
}
