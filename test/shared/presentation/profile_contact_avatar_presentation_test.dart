import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/shared/presentation/profile_contact_avatar_presentation.dart';

void main() {
  test('derives stable initials, color slots, and semantic labels', () {
    const contact = NavivoxProfileContact(
      serverId: 'local',
      profileId: 'mineru',
      displayName: 'Mineru Builder',
      serverLabel: 'Local Gormes',
      health: NavivoxProfileHealth.online,
      latestPreview: '',
      avatarSeed: 'local:work-mineru-repo',
    );

    final presentation = ProfileContactAvatarPresentation(contact);

    expect(presentation.initial, 'M');
    expect(presentation.colorIndex, 2);
    expect(presentation.semanticLabel, 'Mineru Builder profile avatar');
  });

  test('falls back through profile id, server id, and caller fallback', () {
    expect(
      ProfileContactAvatarPresentation(
        const NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: ' ',
          serverLabel: 'Local Gormes',
          health: NavivoxProfileHealth.online,
          latestPreview: '',
        ),
      ).initial,
      'M',
    );
    expect(
      ProfileContactAvatarPresentation(
        const NavivoxProfileContact(
          serverId: 'local',
          profileId: ' ',
          displayName: ' ',
          serverLabel: 'Local Gormes',
          health: NavivoxProfileHealth.online,
          latestPreview: '',
        ),
      ).semanticLabel,
      'local profile avatar',
    );
    expect(
      ProfileContactAvatarPresentation(
        const NavivoxProfileContact(
          serverId: ' ',
          profileId: ' ',
          displayName: ' ',
          serverLabel: 'Local Gormes',
          health: NavivoxProfileHealth.online,
          latestPreview: '',
        ),
      ).initial,
      'P',
    );
  });
}
