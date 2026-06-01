import 'config_admin_value_codec.dart';

class NavivoxConfigAdminChange {
  const NavivoxConfigAdminChange({
    required this.key,
    required this.value,
    this.delete = false,
  });

  final String key;
  final Object? value;
  final bool delete;

  Map<String, Object?> toJson() {
    return {
      'key': configAdminRequiredKey(key),
      'value': configAdminWireValue(value),
      if (delete) 'delete': true,
    };
  }
}
