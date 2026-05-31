import 'package:navivox/core/channel/navivox_channel.dart';

import '../../../../support/test_navivox_channel.dart';
import '../../../shared/fixtures/profile_contact_channel_fixtures.dart';
import '../../../shared/fixtures/profile_contact_fixtures.dart';
import 'profile_scope_test_contracts.dart';

/// Shared local Mineru Profile contact used by chat command/selection tests.
const chatMineruBuilderContact = NavivoxProfileContact(
  serverId: chatMineruServerId,
  profileId: chatMineruProfileId,
  displayName: 'Mineru Builder',
  serverLabel: 'local',
  health: NavivoxProfileHealth.online,
  latestPreview: 'Ready',
);

/// Shared office Support Triage Profile contact used by forwarding/actions tests.
const chatSupportTriageContact = NavivoxProfileContact(
  serverId: chatSupportServerId,
  profileId: chatSupportProfileId,
  displayName: 'Support Triage',
  serverLabel: 'office',
  health: NavivoxProfileHealth.online,
  latestPreview: 'Watching tickets',
);

/// Shared Profile contact fixture scoped through the canonical chat Profile contract.
NavivoxProfileContact chatProfileContact({
  ChatProfileScope scope = chatMineruProfileScope,
  String displayName = 'Mineru',
  String serverLabel = 'Local',
  NavivoxProfileHealth health = NavivoxProfileHealth.online,
  String latestPreview = 'Ready',
  bool micAvailable = false,
}) {
  return NavivoxProfileContact(
    serverId: scope.serverId,
    profileId: scope.profileId,
    displayName: displayName,
    serverLabel: serverLabel,
    health: health,
    latestPreview: latestPreview,
    micAvailable: micAvailable,
  );
}

/// Shared chat test channel with the default local Mineru Profile contact.
TestNavivoxChannel mineruReadyProfileChannel({bool micAvailable = false}) {
  return profileContactChannel(
    servers: const [
      NavivoxServer(
        id: chatMineruServerId,
        name: chatMineruServerId,
        status: 'connected',
      ),
    ],
    contacts: [
      mineruBuilderProfile(
        displayName: 'Mineru',
        latestPreview: 'Ready',
        workspaceRootCount: 1,
        micAvailable: micAvailable,
      ),
    ],
  );
}
