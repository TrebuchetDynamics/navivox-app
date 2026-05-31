import '../../shared/navivox_gateway_json.dart';
import '../contracts/navivox_gateway_message_fields.dart';

/// Typed WebSocket message sent to the Navivox gateway.
class NavivoxGatewayMessage {
  const NavivoxGatewayMessage._(this.body);

  factory NavivoxGatewayMessage.ping({required String requestId}) {
    return NavivoxGatewayMessage._(
      navivoxGatewayRequestEnvelope(
        type: navivoxGatewayPingMessageType,
        requestId: requestId,
      ),
    );
  }

  factory NavivoxGatewayMessage.startTurn({
    required String requestId,
    String? sessionId,
    required String text,
    Map<String, Object?> metadata = const {
      'client': 'navivox',
      'platform': 'flutter',
    },
  }) {
    return NavivoxGatewayMessage._({
      ...navivoxGatewayRequestEnvelope(
        type: navivoxGatewayStartTurnMessageType,
        requestId: requestId,
        sessionId: navivoxGatewayHasText(sessionId) ? sessionId : null,
      ),
      navivoxGatewayTextField: text,
      navivoxGatewayMetadataField: metadata,
    });
  }

  factory NavivoxGatewayMessage.cancelTurn({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._(
      navivoxGatewayRequestEnvelope(
        type: navivoxGatewayCancelTurnMessageType,
        requestId: requestId,
        sessionId: sessionId,
      ),
    );
  }

  factory NavivoxGatewayMessage.stopTurn({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._(
      navivoxGatewayRequestEnvelope(
        type: navivoxGatewayStopTurnMessageType,
        requestId: requestId,
        sessionId: sessionId,
      ),
    );
  }

  factory NavivoxGatewayMessage.subscribeSession({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._(
      navivoxGatewayRequestEnvelope(
        type: navivoxGatewaySubscribeSessionMessageType,
        requestId: requestId,
        sessionId: sessionId,
      ),
    );
  }

  final Map<String, Object?> body;
}
