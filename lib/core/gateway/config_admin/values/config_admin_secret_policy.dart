import '../../../protocol/config_wire_fields.dart';
import '../../shared/navivox_gateway_json.dart';

/// Returns whether a config-admin field/value must be handled as secret.
///
/// Gateways may identify secret config through either an explicit `secret` flag
/// or a `type: secret` field. Keeping that compatibility rule in one place
/// avoids leaking raw values when one signal is absent.
bool configAdminIsSecret(Map<String, Object?> json) {
  return navivoxGatewayBoolField(json, 'secret') ||
      configWireString(json['type']) == 'secret';
}
