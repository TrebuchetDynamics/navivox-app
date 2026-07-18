import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/gateway/screens/gateway_screen.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument _capabilities({bool detailedHealth = true}) =>
    HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {'type': 'bearer', 'required': true},
      'endpoints': {
        if (detailedHealth)
          'health_detailed': {'method': 'GET', 'path': '/health/detailed'},
      },
    });

const _initialHealth = HermesHealthStatus(
  status: 'ok',
  platform: 'hermes-agent',
  version: '0.18.0',
  gatewayState: 'running',
  activeAgents: 1,
);

Widget _testApp(
  FakeHermesChannel channel, {
  double textScale = 1,
  HermesGatewayDirectory? directory,
}) => ProviderScope(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    if (directory != null)
      hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const GatewayScreen(),
  ),
);

void main() {
  testWidgets(
    'shows advertised bounded gateway status without admin controls',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _capabilities(),
        detailedHealth: _initialHealth,
      );
      addTearDown(channel.dispose);

      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();

      expect(find.text('Gateway'), findsWidgets);
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('hermes-agent'), findsOneWidget);
      expect(find.text('0.18.0'), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('Read-only gateway status'), findsOneWidget);
      expect(find.text('Restart'), findsNothing);
      expect(find.text('Configure'), findsNothing);
      expect(find.text('Logs'), findsNothing);
    },
  );

  testWidgets('refresh reloads detailed health through the channel seam', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      detailedHealth: _initialHealth,
      refreshedDetailedHealth: const HermesHealthStatus(
        status: 'ok',
        platform: 'hermes-agent',
        version: '0.18.1',
        gatewayState: 'running',
        activeAgents: 3,
      ),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-refresh-button')));
    await tester.pumpAndSettle();

    expect(channel.loadDetailedHealthCalls, 1);
    expect(find.text('0.18.1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('unsupported detailed health fails closed and hides stale data', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(detailedHealth: false),
      detailedHealth: _initialHealth,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('This gateway did not advertise detailed health status.'),
      findsOneWidget,
    );
    expect(find.text('0.18.0'), findsNothing);
    expect(find.byKey(const ValueKey('gateway-refresh-button')), findsNothing);
  });

  testWidgets('health load failure does not expose raw errors or stale data', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      detailedHealth: _initialHealth,
      optionalResourceErrors: const {
        HermesOptionalResource.detailedHealth:
            'private gateway process path and stack trace',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Detailed gateway status could not be loaded from Hermes.'),
      findsOneWidget,
    );
    expect(find.textContaining('private gateway'), findsNothing);
    expect(find.text('0.18.0'), findsNothing);
  });

  testWidgets('gateway picker activates the selected saved gateway', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha',
          baseUrl: 'https://alpha',
        ),
        HermesEndpointConfig(
          id: 'beta',
          label: 'Beta',
          baseUrl: 'https://beta',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
        'beta': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(_testApp(channel, directory: directory));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-status-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(directory.activeContactId?.gatewayId, 'beta');
    expect(channel.connectCalls.last.baseUrl, 'https://beta');
  });

  testWidgets('retains gateway status at 200% text scale', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      detailedHealth: _initialHealth,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Healthy'), findsOneWidget);
  });
}
