import '../../gateway/navivox_gateway_protocol.dart';
import '../../protocol/navivox_event.dart';

/// Builds safety and approval messages from gateway events.
///
/// Warning events and approval events share the same scoped safety-notice
/// payload contract. Keeping that mapping together prevents those event types
/// from drifting into plain text messages or losing run/profile scope.
NavivoxChatMessage navivoxGatewaySafetyWarningMessage({
  required NavivoxGatewayEvent event,
  required String id,
  required DateTime createdAt,
  required ({String? serverId, String? profileId}) scope,
}) {
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.system,
    kind: NavivoxMessageKind.safetyWarning,
    createdAt: createdAt,
    safetyNotice: NavivoxSafetyNotice(
      id: id,
      severity: event.severity ?? 'warning',
      message: event.message ?? 'Safety warning',
      risk: event.risk,
    ),
    runRecordReference: event.runRecordReference,
    serverId: scope.serverId,
    profileId: scope.profileId,
  );
}

NavivoxToolApproval navivoxGatewayToolApproval({
  required String id,
  required String prompt,
  required String? risk,
}) {
  return NavivoxToolApproval(
    id: id,
    status: 'approval_required',
    prompt: prompt,
    risk: risk,
  );
}

NavivoxChatMessage navivoxGatewayApprovalRequestMessage({
  required NavivoxGatewayEvent event,
  required String id,
  required String toolCallId,
  required String prompt,
  required String? risk,
  required DateTime createdAt,
  required ({String? serverId, String? profileId}) scope,
}) {
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.system,
    kind: NavivoxMessageKind.approvalRequest,
    createdAt: createdAt,
    safetyNotice: NavivoxSafetyNotice(
      id: id,
      approvalId: id,
      toolCallId: toolCallId,
      message: prompt,
      risk: risk,
    ),
    runRecordReference: event.runRecordReference,
    serverId: scope.serverId,
    profileId: scope.profileId,
  );
}
