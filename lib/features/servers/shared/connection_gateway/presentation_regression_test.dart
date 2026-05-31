import 'presentation.dart';

void main() {
  parsesBareIpv6AddressWithSeparatePort();
  preservesExplicitDefaultPortFromUriAddress();
  rejectsOutOfRangePortEmbeddedInUriAddress();
}

void parsesBareIpv6AddressWithSeparatePort() {
  const presentation = GatewayConnectionPresentation();

  final result = presentation.parseAddressPort(address: '::1', port: '8080');

  _expect(!result.hasError, 'bare IPv6 gateway addresses should parse');
  _expect(
    result.address == '::1',
    'IPv6 host should be preserved without brackets',
  );
  _expect(result.port == '8080', 'separate port should be applied');
  _expect(
    result.baseUrl == 'http://[::1]:8080',
    'IPv6 base URL must be bracketed',
  );
}

void preservesExplicitDefaultPortFromUriAddress() {
  const presentation = GatewayConnectionPresentation();

  final result = presentation.parseAddressPort(
    address: 'wss://gateway.example:443/navivox/ws?token=secret',
    port: '',
  );

  _expect(!result.hasError, 'URI-looking gateway addresses should parse');
  _expect(
    result.baseUrl == 'https://gateway.example:443',
    'explicit default websocket port should remain visible in the HTTP base URL, got ${result.baseUrl}',
  );
  _expect(
    result.detectedPortFromAddress,
    'URI address port should be recorded as detected from the address',
  );
}

void rejectsOutOfRangePortEmbeddedInUriAddress() {
  const presentation = GatewayConnectionPresentation();

  final result = presentation.parseAddressPort(
    address: 'http://127.0.0.1:99999',
    port: '',
  );

  _expect(result.hasError, 'out-of-range URI ports should be rejected');
  _expect(
    result.error == 'Enter a valid Gormes gateway address.',
    'invalid embedded URI ports should use the address validation error',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
