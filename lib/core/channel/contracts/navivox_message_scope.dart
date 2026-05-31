/// Server/profile scope attached to channel messages and gateway events.
typedef NavivoxMessageScope = ({String? serverId, String? profileId});

const NavivoxMessageScope navivoxUnscopedMessage = (
  serverId: null,
  profileId: null,
);

NavivoxMessageScope navivoxMessageScope({
  required String? serverId,
  required String? profileId,
}) {
  return (serverId: serverId, profileId: profileId);
}
