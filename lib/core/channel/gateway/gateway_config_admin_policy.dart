import '../../gateway/navivox_gateway_protocol.dart';

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
