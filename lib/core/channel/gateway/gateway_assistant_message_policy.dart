import '../../gateway/navivox_gateway_protocol.dart';
import '../../protocol/navivox_event.dart';

/// Builds assistant transcript messages from gateway events.
///
/// Assistant delta and final-message events share the same message id, scope,
/// and run-record merge contract. Keeping this mapping here prevents the two
/// event paths from drifting as the transcript payload evolves.
NavivoxChatMessage navivoxGatewayAssistantTextMessage({
  required String id,
  required NavivoxGatewayEvent event,
  required NavivoxChatMessage? existing,
  required DateTime createdAt,
  required ({String? serverId, String? profileId}) scope,
  required bool appendText,
}) {
  final incomingText = event.text ?? '';
  final text = appendText
      ? '${existing?.text ?? ''}$incomingText'
      : incomingText;
  return NavivoxChatMessage(
    id: id,
    author: existing?.author ?? NavivoxMessageAuthor.assistant,
    kind: existing?.kind ?? NavivoxMessageKind.text,
    createdAt: existing?.createdAt ?? createdAt,
    text: text,
    runRecordReference:
        event.runRecordReference ?? existing?.runRecordReference,
    serverId: existing?.serverId ?? scope.serverId,
    profileId: existing?.profileId ?? scope.profileId,
  );
}
