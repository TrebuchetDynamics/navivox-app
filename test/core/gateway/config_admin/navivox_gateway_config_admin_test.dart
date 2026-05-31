import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/config_admin/navivox_gateway_config_admin.dart';

void main() {
  test('preserves enum_values as config admin allowed values', () {
    final field = NavivoxConfigAdminField.fromJson(const {
      'path': 'navivox.exposure_mode',
      'type': 'enum',
      'label': 'Exposure mode',
      'enum_values': ['local', 'tunnel'],
    });

    expect(field.allowed, ['local', 'tunnel']);
    expect(field.toFormField()['allowed'], ['local', 'tunnel']);
  });
}
