import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navivox/app.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/router/app_router.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/shared/widgets/app_shell.dart';

import '../features/servers/setup/shared/setup_screen_test_contracts.dart';
import '../support/test_navivox_channel.dart';

void main() {
  testWidgets('router starts at setup when no server is configured', (
    tester,
  ) async {
    await tester.pumpWidget(const NavivoxApp());
    await tester.pumpAndSettle();

    expect(find.text('Connect to Gormes'), findsOneWidget);
    await expandManualEntry(tester);
    expect(find.text('Connect and talk'), findsOneWidget);
  });

  testWidgets('router mounts config section routes through the config screen', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..emitConfigSchema(const {
        'sections': [
          {
            'id': 'providers',
            'label': 'Provider and Models',
            'fields': ['providers.default'],
          },
          {
            'id': 'gateway',
            'label': 'Navivox Gateway',
            'fields': ['navivox.exposure_mode'],
          },
        ],
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
          {'path': 'navivox.exposure_mode', 'label': 'Exposure mode'},
        ],
      })
      ..emitConfigValues(const {
        'providers.default': 'openai',
        'navivox.exposure_mode': 'local',
      });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.byType(AppShell)),
    ).go(AppRoutes.configSectionLocation('providers'));
    await tester.pumpAndSettle();

    expect(find.text('Route not found: /config/providers'), findsNothing);
    expect(find.text('Provider and Models'), findsOneWidget);
    expect(find.text('Default provider'), findsOneWidget);
    expect(find.text('Navivox Gateway'), findsNothing);
    expect(find.text('Exposure mode'), findsNothing);
  });

  // Deferred: a successful chat path through the HTTP gateway needs a
  // fixture WebSocket server. Tracked under 9.E in progress.json as a
  // follow-up integration row; the SSH-era fake-server flow was deleted
  // alongside the wire protocol.
}

class _RouterTestApp extends ConsumerWidget {
  const _RouterTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
