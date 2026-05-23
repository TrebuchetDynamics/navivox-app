import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/profile_contacts/profile_contact_list_presentation.dart';

const _servers = [
  NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
  NavivoxServer(id: 'office', name: 'Office', status: 'offline'),
];

final _contacts = [
  NavivoxProfileContact(
    serverId: 'office',
    profileId: 'support',
    displayName: 'Support Triage',
    serverLabel: 'office',
    health: NavivoxProfileHealth.needsAuth,
    latestPreview: 'Waiting for token',
    latestAt: DateTime(2026, 5, 16, 9, 22),
    workspaceRootCount: 1,
    attentionBadges: ['auth'],
    micAvailable: false,
  ),
  NavivoxProfileContact(
    serverId: 'local',
    profileId: 'mineru',
    displayName: 'Mineru Builder',
    serverLabel: 'local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready to work on mineru',
    latestAt: DateTime(2026, 5, 16, 9, 41),
    workspaceRootCount: 2,
    micAvailable: true,
  ),
  NavivoxProfileContact(
    serverId: 'local',
    profileId: 'personal',
    displayName: 'Personal',
    serverLabel: 'local',
    health: NavivoxProfileHealth.offline,
    latestPreview: 'Gateway unavailable',
    latestAt: DateTime(2026, 5, 15, 18),
    workspaceRootCount: 0,
    attentionBadges: ['offline'],
    micAvailable: false,
  ),
];

void main() {
  test('sorts all Profile contacts and exposes visible state', () {
    final presentation = ProfileContactListPresentation.fromContacts(
      servers: _servers,
      contacts: _contacts,
    );

    expect(presentation.allContacts.map((contact) => contact.displayName), [
      'Mineru Builder',
      'Personal',
      'Support Triage',
    ]);
    expect(presentation.visibleContacts, presentation.allContacts);
    expect(presentation.hasContacts, isTrue);
    expect(presentation.hasVisibleContacts, isTrue);
    expect(presentation.showServerFilter, isTrue);
    expect(presentation.visibleCountLabel, '3 profiles');
  });

  test('filters Profile contacts by selected Gormes gateway', () {
    final presentation = ProfileContactListPresentation.fromContacts(
      servers: _servers,
      contacts: _contacts,
      selectedServerId: 'office',
    );

    expect(presentation.visibleContacts.map((contact) => contact.displayName), [
      'Support Triage',
    ]);
    expect(presentation.visibleCountLabel, '1 profile');
  });

  test('searches Profile contacts using presentation search terms', () {
    final authPresentation = ProfileContactListPresentation.fromContacts(
      servers: _servers,
      contacts: _contacts,
      query: 'auth required',
    );
    final micPresentation = ProfileContactListPresentation.fromContacts(
      servers: _servers,
      contacts: _contacts,
      query: 'mic unavailable',
    );

    expect(
      authPresentation.visibleContacts.map((contact) => contact.displayName),
      ['Support Triage'],
    );
    expect(
      micPresentation.visibleContacts.map((contact) => contact.displayName),
      ['Personal', 'Support Triage'],
    );
  });

  test('reports empty and no-visible-results states separately', () {
    final empty = ProfileContactListPresentation.fromContacts(
      servers: _servers,
      contacts: const [],
    );
    final noResults = ProfileContactListPresentation.fromContacts(
      servers: _servers,
      contacts: _contacts,
      query: 'missing',
    );

    expect(empty.hasContacts, isFalse);
    expect(empty.hasVisibleContacts, isFalse);
    expect(empty.visibleCountLabel, '0 profiles');
    expect(noResults.hasContacts, isTrue);
    expect(noResults.hasVisibleContacts, isFalse);
    expect(noResults.visibleCountLabel, '0 profiles');
  });
}
