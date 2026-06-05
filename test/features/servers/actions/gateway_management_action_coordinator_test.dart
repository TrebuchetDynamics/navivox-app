import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/servers/actions/gateway_management_action_coordinator.dart';
import 'package:navivox/features/servers/overview/presentation/servers_screen_presentation.dart';
import 'package:navivox/features/servers/models/connection_gateway.dart';

void main() {
  const coordinator = GatewayManagementActionCoordinator();

  test('profile selection maps to select-and-open-chat effect', () {
    const profile = GatewayProfileContactPresentation(
      NavivoxProfileContact(
        serverId: 'local',
        profileId: 'mineru',
        displayName: 'Mineru Builder',
        serverLabel: 'Local Gormes',
        health: NavivoxProfileHealth.online,
        latestPreview: 'Ready',
      ),
    );

    final effect = coordinator.selectProfile(profile);

    expect(effect, isA<SelectGatewayProfileAndOpenChatEffect>());
    expect((effect as SelectGatewayProfileAndOpenChatEffect).serverId, 'local');
    expect(effect.profileId, 'mineru');
  });

  test('disconnect confirmation maps to disconnect or noop plans', () {
    expect(
      coordinator.afterDisconnectConfirmation(true),
      isA<DisconnectGatewayPlan>(),
    );
    expect(
      coordinator.afterDisconnectConfirmation(false),
      isA<NoopGatewayDisconnectPlan>(),
    );
    expect(
      coordinator.afterDisconnectConfirmation(null),
      isA<NoopGatewayDisconnectPlan>(),
    );
  });

  test(
    'disconnect outcomes map to snackbar effects with presentation copy',
    () {
      final gateway = _gateway();

      final success = coordinator.disconnectSucceeded(gateway);
      expect(success, isA<CloseGatewaySheetAndShowSnackbarEffect>());
      expect(
        (success as CloseGatewaySheetAndShowSnackbarEffect).message,
        'Disconnected Local Gormes',
      );

      final failed = coordinator.disconnectFailed(gateway, 'network down');
      expect(failed, isA<ShowGatewaySnackbarEffect>());
      expect(
        (failed as ShowGatewaySnackbarEffect).message,
        'Disconnect failed: network down',
      );
    },
  );

  test('register gateway outcomes map connection result copy to snackbars', () {
    const request = GatewayConnectionRequest(
      baseUrl: 'http://127.0.0.1:7319',
      token: 'secret-token',
    );

    final passed = coordinator.registerConnectionPassed(
      (request) => 'passed ${request.baseUrl}',
      request,
    );
    expect(passed, isA<ShowGatewaySnackbarEffect>());
    expect(
      (passed as ShowGatewaySnackbarEffect).message,
      'passed http://127.0.0.1:7319',
    );

    final failed = coordinator.registerConnectionFailed(
      (error) => 'failed $error',
      'timeout',
    );
    expect(failed, isA<ShowGatewaySnackbarEffect>());
    expect((failed as ShowGatewaySnackbarEffect).message, 'failed timeout');
  });
}

ServerGatewayPresentation _gateway() {
  return const ServerGatewayPresentation(
    server: NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
    profileContacts: [],
    active: true,
    activeProfileContact: null,
  );
}
