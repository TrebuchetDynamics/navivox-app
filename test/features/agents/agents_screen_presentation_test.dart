import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/agents/agents_screen_presentation.dart';

import '../shared/fixtures/profile_contact_fixtures.dart';
import '../shared/fixtures/seed_fixtures.dart';

final _servers = localOfficeServers();
final _profiles = [
  supportTriageProfile(),
  personalProfile(),
  mineruBuilderProfile(latestAt: DateTime(2026, 5, 16, 9, 41)),
];

void main() {
  test('keeps legacy agent rows behind the Profiles surface', () {
    final presentation = AgentsScreenPresentation.fromState(
      NavivoxChannelState(
        agents: defaultSeedAgents,
        selectedAgentId: 'arch',
        servers: _servers,
        activeServerId: 'local',
        profileContacts: _profiles,
        selectedProfileContactKey: 'local::mineru',
      ),
    );

    expect(presentation.screenTitle, 'Profiles');
    expect(presentation.refreshProfilesTooltip, 'Refresh profiles');
    expect(presentation.showAgentList, isTrue);
    expect(presentation.showProfileFallback, isFalse);
    expect(presentation.showEmptyProfileState, isFalse);
    expect(presentation.agents, defaultSeedAgents);
    expect(presentation.selectedAgentId, 'arch');
  });

  test('shows active-server Profile contacts when the agent list is empty', () {
    final presentation = AgentsScreenPresentation.fromState(
      NavivoxChannelState(
        servers: _servers,
        activeServerId: 'local',
        profileContacts: _profiles,
        selectedProfileContactKey: 'local::mineru',
      ),
    );

    expect(presentation.showAgentList, isFalse);
    expect(presentation.showProfileFallback, isTrue);
    expect(presentation.showEmptyProfileState, isFalse);
    expect(presentation.profileServerLabel, 'Local Gormes');
    expect(presentation.profileFallbackTitle, 'Profiles on Local Gormes');
    expect(
      presentation.profileFallbackSubtitle,
      'Loaded from Gormes profile contacts. Select one profile to scope chat, memory, and config.',
    );
    expect(presentation.selectedProfileContactKey, 'local::mineru');
    expect(presentation.profileContacts.map((profile) => profile.displayName), [
      'Mineru Builder',
      'Personal',
    ]);
  });

  test('falls back to the first visible Profile contact server label', () {
    final presentation = AgentsScreenPresentation.fromState(
      NavivoxChannelState(profileContacts: _profiles),
    );

    expect(presentation.profileServerLabel, 'local');
    expect(presentation.profileContacts.map((profile) => profile.displayName), [
      'Mineru Builder',
      'Personal',
      'Support Triage',
    ]);
  });

  test(
    'reports empty Profile contact state when no fallback contact is visible',
    () {
      final presentation = AgentsScreenPresentation.fromState(
        NavivoxChannelState(
          servers: _servers,
          activeServerId: 'office',
          profileContacts: [_profiles.last],
        ),
      );

      expect(presentation.showAgentList, isFalse);
      expect(presentation.showProfileFallback, isFalse);
      expect(presentation.showEmptyProfileState, isTrue);
      expect(presentation.profileServerLabel, 'Office');
      expect(
        presentation.emptyProfilesTitle,
        'No profiles found on this server',
      );
      expect(
        presentation.emptyProfilesSubtitle,
        'Connect to a Gormes gateway, refresh profiles, or draft a new profile from a seed.',
      );
      expect(presentation.refreshProfilesLabel, 'Refresh profiles');
      expect(presentation.createImportProfileLabel, 'Add profile');
      expect(presentation.createImportProfileSheetTitle, 'Add a profile');
      expect(
        presentation.createImportProfileSheetSubtitle,
        'Create from a natural-language seed through Gormes, or add another gateway that already has profiles.',
      );
      expect(presentation.createFromSeedTitle, 'Create from seed');
      expect(
        presentation.createFromSeedSubtitle,
        'Ask Gormes to draft a profile from natural language.',
      );
      expect(presentation.addGatewayTitle, 'Add gateway');
      expect(
        presentation.addGatewaySubtitle,
        'Register another Gormes gateway and refresh its profile contacts.',
      );
      expect(presentation.profileContacts, isEmpty);
    },
  );
}
