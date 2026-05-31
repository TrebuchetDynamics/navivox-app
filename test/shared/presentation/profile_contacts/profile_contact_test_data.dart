import 'package:navivox/core/channel/navivox_channel.dart';

const mineruProfileContact = NavivoxProfileContact(
  serverId: 'srv1',
  profileId: 'mineru',
  displayName: 'Mineru Builder',
  serverLabel: 'Local',
  health: NavivoxProfileHealth.warning,
  latestPreview: 'Ready',
  workspaceRootCount: 4,
  workspaceRootsWarning: 2,
  workspaceRootsError: 1,
);

NavivoxProfileContact profileContactFixture({
  String serverId = 'srv1',
  String profileId = 'mineru',
  String displayName = 'Mineru Builder',
  String serverLabel = 'Local',
  NavivoxProfileHealth health = NavivoxProfileHealth.online,
  String latestPreview = 'Ready',
  int workspaceRootCount = 0,
  int workspaceRootsWarning = 0,
  int workspaceRootsError = 0,
  bool workspaceRootsOk = true,
  bool micAvailable = true,
  String activeTurnState = 'idle',
  String avatarSeed = '',
}) {
  return NavivoxProfileContact(
    serverId: serverId,
    profileId: profileId,
    displayName: displayName,
    serverLabel: serverLabel,
    health: health,
    latestPreview: latestPreview,
    workspaceRootCount: workspaceRootCount,
    workspaceRootsWarning: workspaceRootsWarning,
    workspaceRootsError: workspaceRootsError,
    workspaceRootsOk: workspaceRootsOk,
    micAvailable: micAvailable,
    activeTurnState: activeTurnState,
    avatarSeed: avatarSeed,
  );
}
