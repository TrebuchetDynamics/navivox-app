import '../../core/channel/navivox_channel.dart';
import '../profile_contacts/profile_contact_list_presentation.dart';

class AgentsScreenPresentation {
  const AgentsScreenPresentation({
    required this.agents,
    required this.selectedAgentId,
    required this.profileContacts,
    required this.selectedProfileContactKey,
    required this.profileServerLabel,
  });

  factory AgentsScreenPresentation.fromState(NavivoxChannelState state) {
    final profileList = ProfileContactListPresentation.fromContacts(
      servers: state.servers,
      contacts: state.profileContacts,
      selectedServerId: state.activeServerId,
    );
    final profileContacts = profileList.visibleContacts;

    return AgentsScreenPresentation(
      agents: List.unmodifiable(state.agents),
      selectedAgentId: state.selectedAgentId,
      profileContacts: profileContacts,
      selectedProfileContactKey: state.selectedProfileContactKey,
      profileServerLabel: _profileServerLabel(state, profileContacts),
    );
  }

  final List<NavivoxAgent> agents;
  final String? selectedAgentId;
  final List<NavivoxProfileContact> profileContacts;
  final String? selectedProfileContactKey;
  final String profileServerLabel;

  String get screenTitle => 'Agents';

  String get refreshProfilesTooltip => 'Refresh profiles';

  String get profileFallbackTitle => 'Profiles on $profileServerLabel';

  String get profileFallbackSubtitle =>
      'Loaded from Gormes profile contacts. Select one profile to scope chat, memory, and config.';

  String get emptyProfilesTitle => 'No profiles found on this server';

  String get emptyProfilesSubtitle =>
      'Connect to a Gormes server, then refresh profiles or create/import a profile.';

  String get refreshProfilesLabel => 'Refresh profiles';

  String get createImportProfileLabel => 'Create or import profile';

  String get createImportProfileSheetTitle => 'Create or import profile';

  String get createImportProfileSheetSubtitle =>
      'Server-backed profile creation and import will be wired to the Gormes profile API in the next slice.';

  bool get showAgentList => agents.isNotEmpty;
  bool get showProfileFallback => !showAgentList && profileContacts.isNotEmpty;
  bool get showEmptyProfileState => !showAgentList && profileContacts.isEmpty;

  static String _profileServerLabel(
    NavivoxChannelState state,
    List<NavivoxProfileContact> profileContacts,
  ) {
    final activeServer = state.activeServer;
    if (activeServer != null) return activeServer.name;
    if (profileContacts.isNotEmpty) return profileContacts.first.serverLabel;
    return 'selected server';
  }
}
