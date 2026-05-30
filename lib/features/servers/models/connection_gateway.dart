// Models for gateway connection address/request payloads.
//
// These value types are shared across the registration, setup,
// and screens subfolders.

class GatewayConnectionAddressPort {
  const GatewayConnectionAddressPort({
    required this.address,
    required this.port,
    required this.baseUrl,
    this.detectedPortFromAddress = false,
  }) : error = null;

  const GatewayConnectionAddressPort.error(this.error)
    : address = null,
      port = null,
      baseUrl = null,
      detectedPortFromAddress = false;

  final String? address;
  final String? port;
  final String? baseUrl;
  final String? error;
  final bool detectedPortFromAddress;

  bool get hasError => error != null;
}

class GatewayConnectionRequest {
  const GatewayConnectionRequest({
    required this.baseUrl,
    this.token,
    this.webSocketUrl,
  });

  final String baseUrl;
  final String? token;
  final String? webSocketUrl;
}
