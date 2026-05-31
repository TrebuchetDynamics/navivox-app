import '../../protocol/navivox_event.dart';

/// Builds local user transcript messages for turns sent to the gateway.
///
/// Text and voice submissions both create a user-visible transcript entry before
/// sending the shared start_turn frame. Centralizing the message construction
/// keeps profile scope and voice payload handling aligned across input modes.
NavivoxChatMessage navivoxGatewayUserTurnMessage({
  required String id,
  required String text,
  required DateTime createdAt,
  required ({String? serverId, String? profileId}) scope,
  NavivoxVoiceMessage? voice,
}) {
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.user,
    kind: voice == null ? NavivoxMessageKind.text : NavivoxMessageKind.voice,
    createdAt: createdAt,
    text: text,
    serverId: scope.serverId,
    profileId: scope.profileId,
    voice: voice,
  );
}
