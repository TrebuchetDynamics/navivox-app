import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/servers/screens/servers_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/app/test_material_app.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

class RecordingConnectChannel extends TestNavivoxChannel {
  final connectCalls =
      <({String baseUrl, String? token, String? webSocketUrl})>[];
  int disconnectCalls = 0;

  @override
  Future<void> connect({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  }) async {
    connectCalls.add((
      baseUrl: baseUrl,
      token: token,
      webSocketUrl: webSocketUrl,
    ));
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
  }
}

void main() {
  testWidgets(
    'servers screen groups profiles by gateway and opens management sheet',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(
          localOfficeServers(office: officeGatewayServer),
          activeServerId: 'local',
        )
        ..seedProfileContacts([
          mineruBuilderProfile(latestPreview: 'Ready'),
          personalProfile(
            health: NavivoxProfileHealth.warning,
            latestPreview: 'Workspace warning',
            workspaceRootCount: 1,
          ),
          supportTriageProfile(),
        ]);

      await tester.pumpWidget(
        TestNavivoxMaterialApp(channel: channel, home: const ServersScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gateways'), findsOneWidget);
      expect(find.byKey(const ValueKey('server-card-local')), findsOneWidget);
      expect(find.byKey(const ValueKey('server-card-office')), findsOneWidget);
      expect(find.text('2 profiles'), findsOneWidget);
      expect(find.text('1 profile'), findsOneWidget);
      expect(find.text('1 warning'), findsOneWidget);
      expect(find.text('1 auth'), findsOneWidget);
      expect(find.byTooltip('Register gateway'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('server-manage-office')));
      await tester.pumpAndSettle();

      expect(find.text('Manage gateway'), findsOneWidget);
      expect(find.text('Office Gateway'), findsWidgets);
      expect(find.text('Server ID'), findsOneWidget);
      expect(find.text('office'), findsWidgets);
      expect(find.text('Profiles on this gateway'), findsOneWidget);
      expect(find.text('Support Triage'), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('server-profile-office-support')),
            )
            .onTap,
        isNotNull,
      );
    },
  );

  testWidgets('gateway cards distinguish active session from registered', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(
        localOfficeServers(office: officeGatewayServer),
        activeServerId: 'local',
      );

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ServersScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active session gateway · online'), findsOneWidget);
    expect(find.text('Registered gateway · offline'), findsOneWidget);
  });

  testWidgets('register gateway action explains connect-info import boundary', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers([localGormesServer], activeServerId: 'local');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ServersScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Register gateway'));
    await tester.pumpAndSettle();

    expect(find.text('Register gateway'), findsOneWidget);
    expect(find.textContaining('gormes navivox connect-info'), findsOneWidget);
    expect(find.textContaining('persistent multi-gateway'), findsOneWidget);
  });

  testWidgets('register gateway sheet can test a Gormes connection', (
    tester,
  ) async {
    final channel = RecordingConnectChannel();

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ServersScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Register gateway'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('register-gateway-label')),
      'Local Gormes',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-gateway-base-url')),
      '  http://127.0.0.1:7319  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-gateway-token')),
      '  secret-token  ',
    );

    await tester.tap(find.byKey(const ValueKey('register-gateway-test')));
    await tester.pumpAndSettle();

    expect(channel.connectCalls, [
      (
        baseUrl: 'http://127.0.0.1:7319',
        token: 'secret-token',
        webSocketUrl: null,
      ),
    ]);
    expect(
      find.text('Connection test passed for http://127.0.0.1:7319'),
      findsOneWidget,
    );
  });

  testWidgets('active gateway management can disconnect the current session', (
    tester,
  ) async {
    final channel = RecordingConnectChannel()
      ..seedServers([localGormesServer], activeServerId: 'local');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ServersScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('server-manage-local')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-disconnect-current')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('server-disconnect-current')));
    await tester.pumpAndSettle();

    expect(find.text('Disconnect Local Gormes?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-disconnect-confirm')));
    await tester.pumpAndSettle();

    expect(channel.disconnectCalls, 1);
    expect(find.text('Disconnected Local Gormes'), findsOneWidget);
  });

  testWidgets('gateway management identifies the active profile contact', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers([localGormesServer], activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(latestPreview: 'Ready', workspaceRootCount: 0),
      ], selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ServersScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('server-manage-local')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-active-profile-local')),
      findsOneWidget,
    );
    expect(find.text('Active profile contact'), findsOneWidget);
    expect(find.text('Mineru Builder · mineru'), findsOneWidget);
  });
}
