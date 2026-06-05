import '../overview/servers_screen_presentation.dart';
import '../models/connection_gateway.dart';

final class GatewayManagementActionCoordinator {
  const GatewayManagementActionCoordinator();

  GatewayManagementEffect selectProfile(
    GatewayProfileContactPresentation profile,
  ) {
    final contact = profile.contact;
    return GatewayManagementEffect.selectProfileAndOpenChat(
      serverId: contact.serverId,
      profileId: contact.profileId,
    );
  }

  GatewayDisconnectPlan afterDisconnectConfirmation(bool? confirmed) {
    return confirmed == true
        ? const GatewayDisconnectPlan.disconnect()
        : const GatewayDisconnectPlan.noop();
  }

  GatewayManagementEffect disconnectSucceeded(
    ServerGatewayPresentation gateway,
  ) {
    return GatewayManagementEffect.closeSheetAndShowSnackbar(
      gateway.disconnectedMessage,
    );
  }

  GatewayManagementEffect disconnectFailed(
    ServerGatewayPresentation gateway,
    Object error,
  ) {
    return GatewayManagementEffect.showSnackbar(
      gateway.disconnectFailedMessage(error),
    );
  }

  GatewayManagementEffect registerConnectionPassed(
    String Function(GatewayConnectionRequest request) messageFor,
    GatewayConnectionRequest request,
  ) {
    return GatewayManagementEffect.showSnackbar(messageFor(request));
  }

  GatewayManagementEffect registerConnectionFailed(
    String Function(Object error) messageFor,
    Object error,
  ) {
    return GatewayManagementEffect.showSnackbar(messageFor(error));
  }
}

sealed class GatewayDisconnectPlan {
  const GatewayDisconnectPlan._();

  const factory GatewayDisconnectPlan.disconnect() = DisconnectGatewayPlan;
  const factory GatewayDisconnectPlan.noop() = NoopGatewayDisconnectPlan;
}

final class DisconnectGatewayPlan extends GatewayDisconnectPlan {
  const DisconnectGatewayPlan() : super._();
}

final class NoopGatewayDisconnectPlan extends GatewayDisconnectPlan {
  const NoopGatewayDisconnectPlan() : super._();
}

sealed class GatewayManagementEffect {
  const GatewayManagementEffect._();

  const factory GatewayManagementEffect.selectProfileAndOpenChat({
    required String serverId,
    required String profileId,
  }) = SelectGatewayProfileAndOpenChatEffect;
  const factory GatewayManagementEffect.closeSheetAndShowSnackbar(
    String message,
  ) = CloseGatewaySheetAndShowSnackbarEffect;
  const factory GatewayManagementEffect.showSnackbar(String message) =
      ShowGatewaySnackbarEffect;
}

final class SelectGatewayProfileAndOpenChatEffect
    extends GatewayManagementEffect {
  const SelectGatewayProfileAndOpenChatEffect({
    required this.serverId,
    required this.profileId,
  }) : super._();

  final String serverId;
  final String profileId;
}

final class CloseGatewaySheetAndShowSnackbarEffect
    extends GatewayManagementEffect {
  const CloseGatewaySheetAndShowSnackbarEffect(this.message) : super._();

  final String message;
}

final class ShowGatewaySnackbarEffect extends GatewayManagementEffect {
  const ShowGatewaySnackbarEffect(this.message) : super._();

  final String message;
}
