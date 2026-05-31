import 'navivox_endpoint_uri.dart';

void main() {
  derivesHttpOriginFromWebSocketEndpointWithoutDroppingExplicitPort();
  stripsPathAndQueryOnlyForHttpBaseUrlDerivation();
  preservesWebSocketPathAndQueryForConnectionEndpoint();
  keepsOriginalValueWhenHttpOriginCannotBeDerived();
}

void derivesHttpOriginFromWebSocketEndpointWithoutDroppingExplicitPort() {
  final result = navivoxHttpBaseUrlFromEndpointString(
    'wss://gateway.example:443/navivox/ws?token=secret',
  );

  _expect(
    result == 'https://gateway.example:443',
    'explicit default ports are part of the endpoint origin contract',
  );
}

void stripsPathAndQueryOnlyForHttpBaseUrlDerivation() {
  final result = navivoxHttpBaseUrlFromEndpointString(
    'https://gateway.example:8443/api?token=secret',
  );

  _expect(result == 'https://gateway.example:8443', 'base URL is origin only');
}

void preservesWebSocketPathAndQueryForConnectionEndpoint() {
  final result = navivoxWebSocketUrlFromEndpointString(
    'wss://gateway.example/navivox/ws?token=secret',
  );

  _expect(
    result == 'wss://gateway.example/navivox/ws?token=secret',
    'websocket endpoint keeps path/query while base URL derivation strips them',
  );
}

void keepsOriginalValueWhenHttpOriginCannotBeDerived() {
  final result = navivoxHttpOriginOrOriginalFromString(
    'ftp://gateway.example/resource',
  );

  _expect(
    result == 'ftp://gateway.example/resource',
    'non-HTTP values are preserved for compatibility instead of rejected',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
