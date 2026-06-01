import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/pairing/pairing_descriptor_query_fields.dart';
import 'package:navivox/core/protocol/pairing/pairing_descriptor_query_pair.dart';

void main() {
  test('replays raw query order across scalar aliases and repeated lists', () {
    final fields = PairingDescriptorQueryFields(
      descriptor: 'navivox://connect?...',
      queryParametersAll: const {},
      rawQuery:
          'server_id=%20&channelIds=telegram&serverId=local&'
          'channel_ids=navivox%2Cdiscord&server_id=shadow',
    );

    expect(fields.optional('server_id'), 'local');
    expect(fields.csv('channel_ids'), ['telegram', 'navivox', 'discord']);
  });

  test(
    'ordered query pairs preserve decoded empty values as replay evidence',
    () {
      final pairs = pairingDescriptorOrderedQueryPairs(
        rawQuery: 'server_id=&channelIds=navivox&tokenRequired=true',
        queryParametersAll: const {},
      );

      expect(pairs.map((pair) => (pair.normalizedName, pair.value)), [
        ('serverid', ''),
        ('channelids', 'navivox'),
        ('tokenrequired', 'true'),
      ]);
    },
  );
}
