import '../../gateway/messages/navivox_gateway_event.dart';
import '../../protocol/navivox_event.dart';
import '../../protocol/navivox_json.dart';
import '../contracts/navivox_channel.dart';

/// Resolves the server/profile scope for gateway transcript events.
///
/// Gateway events may carry scope directly in metadata, or indirectly through
/// the request/tool-call message they update. Keeping the lookup policy here
/// keeps assistant, tool, safety, and approval event handling aligned.
({String? serverId, String? profileId}) navivoxGatewayMessageScopeFromEvent({
  required NavivoxGatewayEvent event,
  required Map<String, NavivoxChatMessage> messages,
}) {
  final metadataServerId = navivoxOptionalStringFromJson(
    event.metadata['server_id'],
  );
  final metadataProfileId = navivoxOptionalStringFromJson(
    event.metadata['profile_id'],
  );
  if (metadataServerId != null && metadataProfileId != null) {
    return (serverId: metadataServerId, profileId: metadataProfileId);
  }

  final requestMessage = event.requestId == null
      ? null
      : messages[event.requestId!];
  final requestScope = _messageScope(requestMessage);
  if (requestScope != null) return requestScope;

  final toolMessage = event.toolCallId == null
      ? null
      : messages[event.toolCallId!];
  final toolScope = _messageScope(toolMessage);
  if (toolScope != null) return toolScope;

  return (serverId: null, profileId: null);
}

({String? serverId, String? profileId})? _messageScope(
  NavivoxChatMessage? message,
) {
  if (message?.profileContactKey == null) return null;
  return (serverId: message!.serverId, profileId: message.profileId);
}
