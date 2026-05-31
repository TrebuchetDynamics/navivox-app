import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/shared/presentation/profile_contact_labels.dart';

import 'profile_contact_test_data.dart';

void main() {
  const profile = mineruProfileContact;

  test('uses safe profile and server fallbacks for blank contacts', () {
    final blankContact = profileContactFixture(
      displayName: ' ',
      serverLabel: ' ',
    );

    expect(
      profileContactDisplayLabel(blankContact, fallback: 'mineru'),
      'mineru',
    );
    expect(
      profileContactServerLabel(blankContact, fallback: 'default'),
      'default',
    );
    expect(profileContactDisplayLabel(null, fallback: 'default'), 'default');
    expect(profileContactServerLabel(null, fallback: 'default'), 'default');
  });

  test(
    'uses display, profile, server, then caller fallback for identity labels',
    () {
      expect(
        profileContactIdentityLabel(profile, fallback: 'profile'),
        'Mineru Builder',
      );
      expect(
        profileContactIdentityLabel(
          profileContactFixture(displayName: ' '),
          fallback: 'profile',
        ),
        'mineru',
      );
      expect(
        profileContactIdentityLabel(
          profileContactFixture(profileId: ' ', displayName: ' '),
          fallback: 'profile',
        ),
        'srv1',
      );
      expect(
        profileContactIdentityLabel(
          profileContactFixture(
            serverId: ' ',
            profileId: ' ',
            displayName: ' ',
          ),
          fallback: 'profile',
        ),
        'profile',
      );
    },
  );

  test('formats project status segments and full status bar labels', () {
    expect(profileContactProjectStatusSegments(profile), [
      '4 projects',
      '1 error',
      '2 warnings',
    ]);
    expect(
      profileContactProjectStatusLabel(profile),
      '4 projects • 1 error • 2 warnings',
    );
    expect(
      profileContactStatusBarLabel(profile),
      'Local • warning • 4 projects • 1 error • 2 warnings',
    );
  });

  test(
    'reports project attention when no counts exist but roots are unhealthy',
    () {
      final profile = profileContactFixture(workspaceRootsOk: false);

      expect(profileContactProjectStatusSegments(profile), [
        'project attention needed',
      ]);
      expect(
        profileContactStatusBarLabel(profile),
        'Local • online • project attention needed',
      );
    },
  );
}
