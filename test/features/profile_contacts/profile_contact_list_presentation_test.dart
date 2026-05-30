import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/profile_contacts/profile_contact_list_presentation.dart';

import '../shared/fixtures/profile_contact_fixtures.dart';

final _servers = localOfficeServers();
final _contacts = sortedProfileListContacts();

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
