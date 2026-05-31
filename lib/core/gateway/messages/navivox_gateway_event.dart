import '../../protocol/navivox_json.dart'
    show navivoxMapFromJson, navivoxOptionalStringFromJson;
import '../shared/navivox_gateway_json.dart';

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
    final metadata = navivoxMapFromJson(json['metadata']);
    final contact = navivoxGatewayOptionalObjectFromJson(json['contact']);
    return NavivoxGatewayEvent(
      type: json['type']?.toString() ?? '',
      requestId: json['request_id']?.toString(),
      sessionId: json['session_id']?.toString(),
      text: json['text']?.toString(),
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      toolName: json['tool_name']?.toString(),
      toolCallId: json['tool_call_id']?.toString(),
      status: json['status']?.toString(),
      safetyId: json['safety_id']?.toString(),
      approvalId: json['approval_id']?.toString(),
      severity: json['severity']?.toString(),
      risk: json['risk']?.toString(),
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

  bool get isError => type == 'error';
}

String? _runRecordReferenceFromJson(
  Map<String, Object?> json,
  Map<String, Object?> metadata,
) {
  return navivoxOptionalStringFromJson(json['run_record_ref']) ??
      navivoxOptionalStringFromJson(json['run_record_reference']) ??
      navivoxOptionalStringFromJson(metadata['run_record_ref']) ??
      navivoxOptionalStringFromJson(metadata['run_record_reference']);
}
