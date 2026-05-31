import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_profile_contact_key.dart';

void main() {
  test('builds stable profile contact keys', () {
    expect(
      navivoxProfileContactKey(serverId: 'server-a', profileId: 'profile-b'),
      'server-a::profile-b',
    );
  });

  test('builds nullable keys from trimmed wire values', () {
    expect(
      navivoxProfileContactKeyFromNullable(
        serverId: ' server-a ',
        profileId: ' profile-b ',
      ),
      'server-a::profile-b',
    );
    expect(
      navivoxProfileContactKeyFromNullable(
        serverId: 'server-a',
        profileId: ' ',
      ),
      isNull,
    );
  });
}
