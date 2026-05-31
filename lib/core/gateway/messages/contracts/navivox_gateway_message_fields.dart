/// Shared wire-field and message-type contract for gateway stream messages.
const navivoxGatewayTypeField = 'type';
const navivoxGatewayRequestIdField = 'request_id';
const navivoxGatewaySessionIdField = 'session_id';
const navivoxGatewayTextField = 'text';
const navivoxGatewayMetadataField = 'metadata';
const navivoxGatewayRunRecordRefField = 'run_record_ref';
const navivoxGatewayRunRecordReferenceField = 'run_record_reference';

const navivoxGatewayPingMessageType = 'ping';
const navivoxGatewayStartTurnMessageType = 'start_turn';
const navivoxGatewayCancelTurnMessageType = 'cancel_turn';
const navivoxGatewayStopTurnMessageType = 'stop_turn';
const navivoxGatewaySubscribeSessionMessageType = 'subscribe_session';

const navivoxGatewayErrorEventType = 'error';
const navivoxGatewayBadResponseCode = 'bad_response';
const navivoxGatewayInvalidEventMessage = 'Invalid gateway event';

/// Builds the shared request envelope used by outbound gateway messages.
Map<String, Object?> navivoxGatewayRequestEnvelope({
  required String type,
  required String requestId,
  String? sessionId,
}) {
  return {
    navivoxGatewayTypeField: type,
    navivoxGatewayRequestIdField: requestId,
    if (sessionId != null) navivoxGatewaySessionIdField: sessionId,
  };
}
