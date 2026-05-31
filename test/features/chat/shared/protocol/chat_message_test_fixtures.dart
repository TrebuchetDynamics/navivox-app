import 'package:navivox/core/protocol/navivox_event.dart';

/// Shared chat message fixture for tests that need scoped Profile-contact turns.
NavivoxChatMessage chatTextMessage({
  required String id,
  required String? text,
  required DateTime createdAt,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.user,
  String? runRecordReference,
  String? serverId,
  String? profileId,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.text,
    createdAt: createdAt,
    text: text,
    runRecordReference: runRecordReference,
    serverId: serverId,
    profileId: profileId,
  );
}
