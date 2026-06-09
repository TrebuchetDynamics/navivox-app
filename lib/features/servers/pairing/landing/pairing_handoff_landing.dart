import '../../../../core/channel/navivox_channel.dart';
import '../../../../core/protocol/navivox_json.dart';
import '../../../../core/protocol/navivox_profile_contact_key.dart';
import '../../../../router/navigation_intent.dart';

import '../../models/connection_import.dart';

class PairingHandoffLanding {
  const PairingHandoffLanding({
    this.serverId,
    this.profileId,
    this.setupIntent = const PairingHandoffSetupIntent(),
  });

  final String? serverId;
  final String? profileId;
  final PairingHandoffSetupIntent setupIntent;

  bool get hasProfileTarget =>
      navivoxOptionalStringFromJson(serverId) != null &&
      navivoxOptionalStringFromJson(profileId) != null;

  NavivoxProfileContact? reportedProfileContact(NavivoxChannelState state) {
    final server = navivoxOptionalStringFromJson(serverId);
    final profile = navivoxOptionalStringFromJson(profileId);
    if (server == null || profile == null) return null;
    final key = navivoxProfileContactKey(serverId: server, profileId: profile);
    for (final contact in state.profileContacts) {
      if (contact.key == key) return contact;
    }
    return null;
  }

  NavigationIntent navigationIntentAfterConnect(NavivoxChannelState state) {
    final contact = reportedProfileContact(state);
    if (contact != null) {
      return OpenChatThread(contact.serverId, contact.profileId);
    }
    if (setupIntent.suggestsConfig && state.configSchema != null) {
      return const OpenConfig();
    }
    return const OpenChatsList();
  }
}
