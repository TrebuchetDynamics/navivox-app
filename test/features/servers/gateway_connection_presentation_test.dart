import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/gateway_connection_presentation.dart';

void main() {
  test('validates supported Gormes gateway URL schemes', () {
    const presentation = GatewayConnectionPresentation();

    expect(
      presentation.validateBaseUrl(''),
      'Enter the Gormes gateway base URL.',
    );
    expect(
      presentation.validateBaseUrl('not a url'),
      'Enter a valid Gormes gateway URL.',
    );
    expect(
      presentation.validateBaseUrl('ftp://example.com'),
      'Use http, https, ws, or wss.',
    );
    expect(presentation.validateBaseUrl('http://127.0.0.1:7319'), isNull);
    expect(presentation.validateBaseUrl('https://gateway.example'), isNull);
    expect(presentation.validateBaseUrl('ws://127.0.0.1:7319'), isNull);
    expect(presentation.validateBaseUrl('wss://gateway.example'), isNull);
  });

  test('builds trimmed connection payload and omits blank token', () {
    const presentation = GatewayConnectionPresentation();

    final withToken = presentation.connectRequest(
      baseUrl: '  http://127.0.0.1:7319  ',
      token: '  secret-token  ',
    );
    final withoutToken = presentation.connectRequest(
      baseUrl: '  ws://127.0.0.1:7319  ',
      token: '   ',
    );

    expect(withToken.baseUrl, 'http://127.0.0.1:7319');
    expect(withToken.token, 'secret-token');
    expect(withoutToken.baseUrl, 'ws://127.0.0.1:7319');
    expect(withoutToken.token, isNull);
  });
}
