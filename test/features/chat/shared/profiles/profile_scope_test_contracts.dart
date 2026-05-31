/// Shared Profile-scope identifiers used by chat feature tests.
///
/// Keeping the canonical server/profile ids in one place makes fixture values
/// and scope assertions agree without coupling tests to individual contact
/// objects.
typedef ChatProfileScope = ({String serverId, String profileId});

const chatMineruServerId = 'local';
const chatMineruProfileId = 'mineru';
const chatMineruProfileScope = (
  serverId: chatMineruServerId,
  profileId: chatMineruProfileId,
);

const chatSupportServerId = 'office';
const chatSupportProfileId = 'support';
const chatSupportProfileScope = (
  serverId: chatSupportServerId,
  profileId: chatSupportProfileId,
);

String chatProfileScopeKey(ChatProfileScope scope) {
  return '${scope.serverId}::${scope.profileId}';
}
