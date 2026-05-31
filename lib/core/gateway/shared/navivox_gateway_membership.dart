/// Exact-token membership helpers for gateway-advertised string lists.
///
/// Capability and action lists are wire-advertised token collections. Membership
/// intentionally remains exact and case-sensitive so UI/readiness checks do not
/// drift into fuzzy matching or prefix semantics.
bool navivoxGatewayContainsAdvertisedToken(
  Iterable<String> tokens,
  String token,
) {
  return tokens.contains(token);
}
