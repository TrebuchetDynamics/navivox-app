import '../../gateway/navivox_gateway_protocol.dart';
import '../contracts/navivox_channel.dart';

/// Gateway config-admin request guard.
///
/// Config refresh/diff/validate/apply share the same connection and advertised
/// availability contract. Keeping the guard outside the channel keeps those
/// call sites aligned without exposing config-admin state mutation.
NavivoxGatewayClient navivoxRequireGatewayConfigAdminClient({
  required NavivoxGatewayClient? client,
  required bool available,
  required String action,
}) {
  if (client == null || !available) {
    throw StateError('Connect to Gormes to $action.');
  }
  return client;
}

/// Applies a config-admin gateway response to channel state.
///
/// Validate, diff, and apply all surface the gateway snapshot through the same
/// `configDiff` field. Apply may also refresh persisted values when the server
/// accepted the change.
NavivoxChannelState navivoxStateWithConfigAdminResponse({
  required NavivoxChannelState state,
  required NavivoxConfigAdminResponse response,
  Map<String, Object?>? nextValues,
}) {
  return state.copyWith(
    configValues: nextValues,
    configDiff: response.snapshot,
  );
}

/// Best-effort value refresh after an applied config-admin mutation.
///
/// A failed refresh should not hide a successful apply response; callers keep
/// the response snapshot and leave current values unchanged.
Future<Map<String, Object?>?> navivoxConfigAdminValuesAfterAppliedResponse({
  required NavivoxGatewayClient client,
  required NavivoxConfigAdminResponse response,
}) async {
  if (!response.applied) return null;
  try {
    return (await client.configAdminValues()).toConfigValues();
  } catch (_) {
    return null;
  }
}
