import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';

import '../../../shared/app/test_material_app.dart';
import '../../../shared/finders/test_finders.dart';
import '../shared/setup_screen_test_contracts.dart';

void main() {
  testWidgets(
    'QR image import fills setup fields and auto-expands manual entry',
    (tester) async {
      await tester.pumpWidget(
        TestProviderMaterialApp(
          home: SetupScreen(
            qrImageImporter: () async => const SetupQrImageImport(
              baseUrl: 'http://10.0.2.2:8765',
              token: 'nvbx_from_qr_picture',
            ),
          ),
        ),
      );

      final importButton = setupImportQrAction();
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      // Auto-expand should have opened the manual entry section.
      final urlField = setupUrlTextField(tester);
      final tokenField = setupTokenTextField(tester);

      expect(urlField.controller?.text, 'http://10.0.2.2:8765');
      expect(tokenField.controller?.text, 'nvbx_from_qr_picture');
      expect(tokenField.obscureText, isTrue);
      expect(find.text('Imported QR connection details.'), findsOneWidget);
      expect(visibleTextContaining('nvbx_from_qr_picture'), findsNothing);
    },
  );

  test('parses Navivox QR URI payloads', () {
    final result = parseNavivoxQrPayload(
      'navivox://connect?base_url=http%3A%2F%2F10.0.2.2%3A8765&token=nvbx_uri_token',
    );

    expect(result?.baseUrl, 'http://10.0.2.2:8765');
    expect(result?.token, 'nvbx_uri_token');
  });

  test('parses Gormes navivox pair QR descriptor rest token', () {
    final result = parseNavivoxQrPayload(
      'navivox://connect?base_url=http%3A%2F%2F127.0.0.1%3A8765&websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&auth_mode=pairing_token&exposure_mode=local&token_required=true&rest_token=nvbx_pair_rest_token&server_id=local&profile_id=mineru',
    );

    expect(result?.baseUrl, 'http://127.0.0.1:8765');
    expect(result?.token, 'nvbx_pair_rest_token');
    expect(result?.serverId, 'local');
    expect(result?.profileId, 'mineru');
  });

  test('derives pair base URL from websocket-only QR descriptors', () {
    final result = parseNavivoxQrPayload(
      'navivox://connect?websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&auth_mode=pairing_token&token_required=true&rest_token=nvbx_ws_only_token',
    );

    expect(result?.baseUrl, 'http://127.0.0.1:8765');
    expect(result?.token, 'nvbx_ws_only_token');
  });

  test('parses connect-info JSON payloads', () {
    final result = parseNavivoxQrPayload('''
{
  "base_url": "http://100.64.1.2:8765",
  "token": "nvbx_json_token"
}
''');

    expect(result?.baseUrl, 'http://100.64.1.2:8765');
    expect(result?.token, 'nvbx_json_token');
  });

  test('preserves JSON base URL query tokens', () {
    final result = parseNavivoxQrPayload('''
{
  "base_url": "https://gateway.example/connect?token=nvbx_json_base"
}
''');

    expect(result?.baseUrl, 'https://gateway.example');
    expect(result?.token, 'nvbx_json_base');
  });

  test('parses Gormes pair JSON descriptors with websocket URL', () {
    final result = parseNavivoxQrPayload('''
{
  "websocket_url": "ws://127.0.0.1:8765/v1/navivox/stream",
  "auth_mode": "pairing_token",
  "token_required": true,
  "rest_token": "nvbx_pair_json_token"
}
''');

    expect(result?.baseUrl, 'http://127.0.0.1:8765');
    expect(result?.token, 'nvbx_pair_json_token');
  });
}
