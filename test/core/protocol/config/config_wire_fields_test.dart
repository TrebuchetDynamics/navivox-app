import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/config_wire_fields.dart';

void main() {
  test(
    'alias candidate replay yields exact keys once before compatibility keys',
    () {
      final candidates = configWireAliasCandidates(
        const {
          'fields': ['exact'],
          'fieldRefs': ['camel'],
          'field_refs': ['snake'],
        },
        const ['fields', 'field_refs'],
      ).toList();

      expect(candidates, [
        ['exact'],
        ['snake'],
        ['camel'],
      ]);
    },
  );

  test('list alias lookup falls through empty preferred aliases', () {
    final values = configWireStringListFromAliases(const {
      'allowed': [],
      'allowedValues': ['local', 'tunnel'],
    }, configAllowedValuesFieldAliases);

    expect(values, ['local', 'tunnel']);
  });
}
