import '../shared/navivox_gateway_membership.dart';

/// Capability-list membership helpers shared by status and capability-document
/// models.
///
/// Gateway status and capability documents expose the same string-list contract:
/// a capability is supported only when the exact advertised token is present.
/// Keeping this tiny contract in one place prevents the two public models from
/// drifting to different matching semantics.
bool navivoxGatewaySupportsCapability(
  Iterable<String> capabilities,
  String capability,
) {
  return navivoxGatewayContainsAdvertisedToken(capabilities, capability);
}
