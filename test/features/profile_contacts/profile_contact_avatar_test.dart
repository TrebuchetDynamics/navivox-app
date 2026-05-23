import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/profile_contacts/profile_contact_avatar.dart';

const _profile = NavivoxProfileContact(
  serverId: 'local',
  profileId: 'mineru',
  displayName: 'Mineru Builder',
  serverLabel: 'Local Gormes',
  health: NavivoxProfileHealth.online,
  latestPreview: '',
);

void main() {
  testWidgets('renders a stable Profile contact initial and semantics label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProfileContactAvatar(contact: _profile)),
      ),
    );

    expect(find.text('M'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Mineru Builder profile avatar'),
      findsOneWidget,
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundColor, Colors.white);
    expect(avatar.backgroundColor, Colors.primaries[13].shade700);
    semantics.dispose();
  });
}
