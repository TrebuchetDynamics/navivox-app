import 'package:navivox/core/channel/navivox_channel.dart';

import '../../../support/test_navivox_channel.dart';
import 'profile_contact_fixtures.dart';

/// Builds a [TestNavivoxChannel] seeded with profile-contact scope data.
///
/// Screen and controller tests use this contract when the behavior under test
/// only needs active server/profile-contact state plus optional extra seeds.
TestNavivoxChannel profileContactChannel({
  NavivoxChannelState initial = const NavivoxChannelState(),
  List<NavivoxServer> servers = const [localReadyServer],
  String activeServerId = 'local',
  List<NavivoxProfileContact>? contacts,
  String selectedKey = 'local::mineru',
}) {
  return TestNavivoxChannel(initial: initial)
    ..seedServers(servers, activeServerId: activeServerId)
    ..seedProfileContacts(
      contacts ?? [mineruBuilderProfile(latestPreview: 'Ready')],
      selectedKey: selectedKey,
    );
}

/// Builds the common Local Gormes + Mineru Builder selected profile scope.
TestNavivoxChannel localGormesMineruChannel({
  NavivoxChannelState initial = const NavivoxChannelState(),
  NavivoxProfileContact? contact,
}) {
  return profileContactChannel(
    initial: initial,
    servers: const [localGormesServer],
    contacts: [
      contact ?? mineruBuilderProfile(latestPreview: 'Goncho memory active'),
    ],
  );
}
