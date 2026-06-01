import '../../../../protocol/navivox_json.dart'
    show navivoxOptionalStringFromJson;
import '../../../shared/navivox_gateway_json.dart';
import '../../contracts/navivox_gateway_message_fields.dart';

/// Typed event received from the Navivox gateway WebSocket stream.
class NavivoxGatewayEvent {
  const NavivoxGatewayEvent({
    required this.type,
    this.requestId,
    this.sessionId,
    this.text,
    this.code,
    this.message,
    this.toolName,
    this.toolCallId,
    this.status,
    this.safetyId,
    this.approvalId,
    this.severity,
    this.risk,
    this.runRecordReference,
    this.metadata = const {},
    this.contact,
  });

  factory NavivoxGatewayEvent.fromJson(Map<String, Object?> json) {
    final metadata = navivoxGatewayEventMetadataFromJson(json);
    final contact = navivoxGatewayOptionalObjectFromJson(json['contact']);
    return NavivoxGatewayEvent(
      type: navivoxGatewayRawStringField(json, navivoxGatewayTypeField),
      requestId: navivoxGatewayOptionalRawStringField(
        json,
        navivoxGatewayRequestIdField,
      ),
      sessionId: navivoxGatewayOptionalRawStringField(
        json,
        navivoxGatewaySessionIdField,
      ),
      text: navivoxGatewayOptionalRawStringField(json, navivoxGatewayTextField),
      code: navivoxGatewayOptionalRawStringField(json, 'code'),
      message: navivoxGatewayOptionalRawStringField(json, 'message'),
      toolName: navivoxGatewayOptionalRawStringField(json, 'tool_name'),
      toolCallId: navivoxGatewayOptionalRawStringField(json, 'tool_call_id'),
      status: navivoxGatewayOptionalRawStringField(json, 'status'),
      safetyId: navivoxGatewayOptionalRawStringField(json, 'safety_id'),
      approvalId: navivoxGatewayOptionalRawStringField(json, 'approval_id'),
      severity: navivoxGatewayOptionalRawStringField(json, 'severity'),
      risk: navivoxGatewayOptionalRawStringField(json, 'risk'),
      runRecordReference: _runRecordReferenceFromJson(json, metadata),
      metadata: metadata,
      contact: contact,
    );
  }

  final String type;
  final String? requestId;
  final String? sessionId;
  final String? text;
  final String? code;
  final String? message;
  final String? toolName;
  final String? toolCallId;
  final String? status;
  final String? safetyId;
  final String? approvalId;
  final String? severity;
  final String? risk;
  final String? runRecordReference;
  final Map<String, Object?> metadata;
  final Map<String, Object?>? contact;

  bool get isError => type == navivoxGatewayErrorEventType;
}

Map<String, Object?> navivoxGatewayEventMetadataFromJson(
  Map<String, Object?> json,
) {
  return navivoxGatewayOptionalObjectFromJson(
        json[navivoxGatewayMetadataField],
      ) ??
      const {};
}

String? _runRecordReferenceFromJson(
  Map<String, Object?> json,
  Map<String, Object?> metadata,
) {
  return navivoxOptionalStringFromJson(json[navivoxGatewayRunRecordRefField]) ??
      navivoxOptionalStringFromJson(
        json[navivoxGatewayRunRecordReferenceField],
      ) ??
      navivoxOptionalStringFromJson(
        metadata[navivoxGatewayRunRecordRefField],
      ) ??
      navivoxOptionalStringFromJson(
        metadata[navivoxGatewayRunRecordReferenceField],
      );
}
