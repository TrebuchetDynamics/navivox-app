import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/models/connection_import.dart';
import 'package:navivox/features/servers/pairing/pairing_intent.dart';
import 'package:navivox/features/servers/pairing/pairing_intent_coordinator.dart';

void main() {
  const coordinator = PairingIntentCoordinator();

  test('manual submit plans a connect effect', () {
    const intent = PairingIntent.submitManualHandoff(
      baseUrl: 'http://127.0.0.1:8765',
      token: 'nvbx_secret',
    );

    final plan = coordinator.plan(intent, hasActiveGateway: false);

    expect(plan.effects, hasLength(1));
    final effect = plan.primaryEffect;
    expect(effect, isA<ConnectPairingEffect>());
    expect((effect as ConnectPairingEffect).intent, same(intent));
  });

  test('imported handoff applies fields without probing by default', () {
    const handoff = SetupQrImageImport(
      baseUrl: 'https://gateway.example:8765',
      token: 'nvbx_import_secret',
      source: PairingHandoffSource.qrImage,
    );
    const intent = PairingIntent.importHandoff(handoff);

    final plan = coordinator.plan(intent, hasActiveGateway: true);

    expect(plan.effects, hasLength(1));
    final effect = plan.primaryEffect;
    expect(effect, isA<ApplyPairingImportEffect>());
    expect((effect as ApplyPairingImportEffect).import.import, handoff);
  });

  test('direct app-open import can auto-connect when no gateway is active', () {
    const handoff = SetupQrImageImport(
      baseUrl: 'http://127.0.0.1:8765',
      token: 'nvbx_direct_secret',
      source: PairingHandoffSource.directAppOpen,
    );

    final plan = coordinator.plan(
      const PairingIntent.importHandoff(handoff),
      hasActiveGateway: false,
      allowImmediateImportedConnect: true,
    );

    expect(plan.effects, hasLength(2));
    expect(plan.primaryEffect, isA<ApplyPairingImportEffect>());
    final followUp = plan.followUpEffect;
    expect(followUp, isA<ConnectPairingEffect>());
    final connect = followUp as ConnectPairingEffect;
    expect(connect.intent.action, PairingIntentAction.confirmHandoff);
    expect(connect.intent.source, PairingHandoffSource.directAppOpen);
  });

  test(
    'imported handoff requires confirmation before active gateway switch',
    () {
      const handoff = SetupQrImageImport(
        baseUrl: 'https://gateway.example:8765',
        token: 'nvbx_shared_secret',
        source: PairingHandoffSource.sharedText,
      );

      final plan = coordinator.plan(
        const PairingIntent.importHandoff(handoff),
        hasActiveGateway: true,
        allowImmediateImportedConnect: true,
      );

      expect(plan.effects, hasLength(2));
      expect(plan.primaryEffect, isA<ApplyPairingImportEffect>());
      final followUp = plan.followUpEffect;
      expect(followUp, isA<RequestPairingConfirmationEffect>());
      expect(
        (followUp as RequestPairingConfirmationEffect).import.import,
        handoff,
      );
    },
  );

  test('reject intent is ignored', () {
    const handoff = SetupQrImageImport(
      baseUrl: 'https://gateway.example:8765',
      source: PairingHandoffSource.sharedText,
    );

    final plan = coordinator.plan(
      const PairingIntent.rejectHandoff(handoff),
      hasActiveGateway: true,
    );

    expect(plan.primaryEffect, isA<IgnorePairingIntentEffect>());
    expect(plan.followUpEffect, isNull);
  });
}
