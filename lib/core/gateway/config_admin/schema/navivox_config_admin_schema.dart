import '../../../protocol/config_wire_fields.dart';
import '../../../protocol/navivox_json.dart';
import '../../shared/navivox_gateway_json.dart';
import '../values/config_admin_secret_policy.dart';
import 'config_admin_schema_field_projection.dart';

class NavivoxConfigAdminField {
  const NavivoxConfigAdminField({
    required this.key,
    required this.type,
    required this.title,
    this.description = '',
    this.secret = false,
    this.allowed = const [],
    this.actions = const [],
    this.reload = '',
  });

  factory NavivoxConfigAdminField.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminField(
      key: configWireStringFromAliases(json, const ['key', 'path']) ?? '',
      type: configWireString(json['type']) ?? 'string',
      title:
          configWireStringFromAliases(json, const ['title', 'label', 'key']) ??
          '',
      description: configWireString(json['description']) ?? '',
      secret: configAdminIsSecret(json),
      allowed: configAdminSchemaAllowedValues(json),
      actions: configAdminSchemaActions(json),
      reload: configWireString(json['reload']) ?? '',
    );
  }

  final String key;
  final String type;
  final String title;
  final String description;
  final bool secret;
  final List<String> allowed;
  final List<String> actions;
  final String reload;

  Map<String, Object?> toFormField() {
    return {
      'key': key,
      'path': key,
      'title': title,
      'label': title,
      'type': type,
      if (description.isNotEmpty) 'description': description,
      if (secret) 'secret': true,
      if (allowed.isNotEmpty) 'allowed': allowed,
      if (actions.isNotEmpty) 'actions': actions,
      if (reload.isNotEmpty) 'reload': reload,
    };
  }
}

class NavivoxConfigAdminSchemaResponse {
  const NavivoxConfigAdminSchemaResponse({
    required this.action,
    this.fields = const [],
  });

  factory NavivoxConfigAdminSchemaResponse.fromJson(Map<String, Object?> json) {
    return NavivoxConfigAdminSchemaResponse(
      action: navivoxStringFieldFromJson(json, 'action'),
      fields: navivoxGatewayObjectListWhereHasText(
        json['fields'],
        NavivoxConfigAdminField.fromJson,
        (field) => field.key,
      ),
    );
  }

  final String action;
  final List<NavivoxConfigAdminField> fields;

  Map<String, Object?> toConfigSchema() {
    return {'fields': fields.map((field) => field.toFormField()).toList()};
  }
}
