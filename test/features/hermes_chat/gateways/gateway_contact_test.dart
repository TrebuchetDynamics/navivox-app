import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';

void main() {
  test('identity includes gateway and profile', () {
    expect(
      const GatewayContactId(gatewayId: 'a', profileId: 'default'),
      isNot(const GatewayContactId(gatewayId: 'b', profileId: 'default')),
    );
  });

  test('contacts sort by latest activity then stable identity', () {
    final contacts = [
      GatewayContact(
        id: const GatewayContactId(gatewayId: 'b', profileId: 'p2'),
        gatewayLabel: 'Beta',
        profileName: 'Two',
        latestSession: const HermesSession(
          id: 's2',
          source: 'test',
          lastActive: '2026-07-16T10:00:00Z',
        ),
        sessionCount: 1,
        availability: GatewayAvailability.online,
      ),
      GatewayContact(
        id: const GatewayContactId(gatewayId: 'a', profileId: 'p1'),
        gatewayLabel: 'Alpha',
        profileName: 'One',
        latestSession: const HermesSession(
          id: 's1',
          source: 'test',
          lastActive: '2026-07-16T11:00:00Z',
        ),
        sessionCount: 1,
        availability: GatewayAvailability.online,
      ),
    ];

    expect(sortGatewayContacts(contacts).map((c) => c.id.gatewayId), [
      'a',
      'b',
    ]);
  });

  test('contacts without activity sort after active contacts', () {
    final sorted = sortGatewayContacts([
      _contact('a', 'missing'),
      _contact('z', 'active', lastActive: '2026-07-16T10:00:00Z'),
    ]);

    expect(sorted.map((contact) => contact.id.profileId), [
      'active',
      'missing',
    ]);
  });

  test('equal activity sorts by gateway then profile', () {
    final sorted = sortGatewayContacts([
      _contact('b', 'p1', lastActive: '2026-07-16T10:00:00Z'),
      _contact('a', 'p2', lastActive: '2026-07-16T10:00:00Z'),
      _contact('a', 'p1', lastActive: '2026-07-16T10:00:00Z'),
    ]);

    expect(sorted.map((contact) => contact.id), [
      const GatewayContactId(gatewayId: 'a', profileId: 'p1'),
      const GatewayContactId(gatewayId: 'a', profileId: 'p2'),
      const GatewayContactId(gatewayId: 'b', profileId: 'p1'),
    ]);
  });

  test('cache JSON omits credentials and transcript previews', () {
    final json = GatewayContact(
      id: const GatewayContactId(gatewayId: 'a', profileId: 'p1'),
      gatewayLabel: 'Alpha',
      profileName: 'One',
      latestSession: const HermesSession(
        id: 's1',
        source: 'test',
        preview: 'private transcript sentinel',
      ),
      sessionCount: 1,
      availability: GatewayAvailability.offline,
    ).toJson();

    expect(
      json.keys.where({'apiKey', 'token', 'authorization'}.contains),
      isEmpty,
    );
    expect(jsonEncode(json), isNot(contains('private transcript sentinel')));
  });
}

GatewayContact _contact(
  String gatewayId,
  String profileId, {
  String? lastActive,
}) => GatewayContact(
  id: GatewayContactId(gatewayId: gatewayId, profileId: profileId),
  gatewayLabel: gatewayId,
  profileName: profileId,
  latestSession: lastActive == null
      ? null
      : HermesSession(
          id: '$gatewayId-$profileId-session',
          source: 'test',
          lastActive: lastActive,
        ),
  sessionCount: lastActive == null ? 0 : 1,
  availability: GatewayAvailability.online,
);
