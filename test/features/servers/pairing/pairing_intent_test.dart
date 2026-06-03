import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/models/connection_import.dart';
import 'package:navivox/features/servers/pairing/pairing_intent.dart';

void main() {
  test('manual pairing intent keeps connection payload separate from copy', () {
    const intent = PairingIntent.submitManualHandoff(
      baseUrl: 'http://127.0.0.1:8765',
      token: 'nvbx_secret_should_not_render',
      webSocketUrl: 'ws://127.0.0.1:8765/v1/navivox/stream',
    );

    expect(intent.action, PairingIntentAction.submitManualHandoff);
    expect(intent.source, PairingHandoffSource.manual);
    expect(intent.baseUrl, 'http://127.0.0.1:8765');
    expect(intent.token, 'nvbx_secret_should_not_render');
    expect(intent.webSocketUrl, 'ws://127.0.0.1:8765/v1/navivox/stream');
    expect(intent.safeSourceLabel, 'manual entry');
    expect(intent.safeSourceLabel, isNot(contains('nvbx_')));
  });

  test('imported pairing intents expose source and confirmation semantics', () {
    const handoff = SetupQrImageImport(
      baseUrl: 'https://gateway.example:8765',
      token: 'nvbx_import_secret',
      source: PairingHandoffSource.sharedText,
    );

    const imported = PairingIntent.importHandoff(handoff);
    const confirmed = PairingIntent.confirmHandoff(handoff);
    const rejected = PairingIntent.rejectHandoff(handoff);

    expect(imported.action, PairingIntentAction.importHandoff);
    expect(imported.source, PairingHandoffSource.sharedText);
    expect(imported.baseUrl, 'https://gateway.example:8765');
    expect(imported.token, 'nvbx_import_secret');
    expect(imported.safeSourceLabel, 'shared text');
    expect(imported.isOperatorConfirmation, isFalse);

    expect(confirmed.isOperatorConfirmation, isTrue);
    expect(rejected.isOperatorConfirmation, isTrue);
    expect(confirmed.safeSourceLabel, isNot(contains('nvbx_')));
    expect(rejected.safeSourceLabel, isNot(contains('nvbx_')));
  });
}
