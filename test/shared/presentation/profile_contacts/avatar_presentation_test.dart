import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/shared/presentation/profile_contact_avatar_presentation.dart';

import 'profile_contact_test_data.dart';

void main() {
  test('derives stable initials, color slots, and semantic labels', () {
    final contact = profileContactFixture(
      serverId: 'local',
      serverLabel: 'Local Gormes',
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
        profileContactFixture(
          serverId: 'local',
          displayName: ' ',
          serverLabel: 'Local Gormes',
          latestPreview: '',
        ),
      ).initial,
      'M',
    );
    expect(
      ProfileContactAvatarPresentation(
        profileContactFixture(
          serverId: 'local',
          profileId: ' ',
          displayName: ' ',
          serverLabel: 'Local Gormes',
          latestPreview: '',
        ),
      ).semanticLabel,
      'local profile avatar',
    );
    expect(
      ProfileContactAvatarPresentation(
        profileContactFixture(
          serverId: ' ',
          profileId: ' ',
          displayName: ' ',
          serverLabel: 'Local Gormes',
          latestPreview: '',
        ),
      ).initial,
      'P',
    );
  });
}
