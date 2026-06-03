import 'pairing_handoff_flow.dart';
import 'pairing_intent.dart';

/// Pure pairing policy for turning operator Pairing intents into setup effects.
///
/// Widget adapters decide how to render or execute these effects. The
/// coordinator only decides whether a handoff is applied, confirmed, connected,
/// or ignored.
final class PairingIntentCoordinator {
  const PairingIntentCoordinator();

  PairingIntentPlan plan(
    PairingIntent intent, {
    required bool hasActiveGateway,
    bool allowImmediateImportedConnect = false,
  }) {
    return switch (intent.action) {
      PairingIntentAction.importHandoff => _planImport(
        intent,
        hasActiveGateway: hasActiveGateway,
        allowImmediateImportedConnect: allowImmediateImportedConnect,
      ),
      PairingIntentAction.confirmHandoff ||
      PairingIntentAction.submitManualHandoff ||
      PairingIntentAction.retryHandoff => PairingIntentPlan.connect(intent),
      PairingIntentAction.rejectHandoff => const PairingIntentPlan.ignore(),
    };
  }

  PairingIntentPlan _planImport(
    PairingIntent intent, {
    required bool hasActiveGateway,
    required bool allowImmediateImportedConnect,
  }) {
    if (intent is! ImportedPairingIntent || !intent.import.hasValues) {
      return const PairingIntentPlan.ignore();
    }
    final flow = PairingHandoffFlow.fromImport(intent.import);
    final followUp = allowImmediateImportedConnect
        ? _followUpForImportedHandoff(
            intent,
            flow: flow,
            hasActiveGateway: hasActiveGateway,
          )
        : null;
    return PairingIntentPlan.applyImport(intent, followUp: followUp);
  }

  PairingIntentEffect? _followUpForImportedHandoff(
    ImportedPairingIntent intent, {
    required PairingHandoffFlow flow,
    required bool hasActiveGateway,
  }) {
    if (flow.requiresActiveGatewayConfirmation(
      hasActiveGateway: hasActiveGateway,
    )) {
      return PairingIntentEffect.requestConfirmation(intent);
    }
    if (flow.shouldAutoConnect(hasActiveGateway: hasActiveGateway)) {
      return PairingIntentEffect.connect(
        PairingIntent.confirmHandoff(intent.import),
      );
    }
    return null;
  }
}

final class PairingIntentPlan {
  const PairingIntentPlan._({required this.primaryEffect, this.followUpEffect});

  PairingIntentPlan.applyImport(
    ImportedPairingIntent import, {
    PairingIntentEffect? followUp,
  }) : this._(
         primaryEffect: ApplyPairingImportEffect(import),
         followUpEffect: followUp,
       );

  PairingIntentPlan.connect(PairingIntent intent)
    : this._(primaryEffect: ConnectPairingEffect(intent));

  const PairingIntentPlan.ignore()
    : this._(primaryEffect: const PairingIntentEffect.ignore());

  final PairingIntentEffect primaryEffect;
  final PairingIntentEffect? followUpEffect;

  Iterable<PairingIntentEffect> get effects sync* {
    yield primaryEffect;
    if (followUpEffect != null) yield followUpEffect!;
  }
}

sealed class PairingIntentEffect {
  const PairingIntentEffect._();

  const factory PairingIntentEffect.applyImport(ImportedPairingIntent import) =
      ApplyPairingImportEffect;

  const factory PairingIntentEffect.requestConfirmation(
    ImportedPairingIntent import,
  ) = RequestPairingConfirmationEffect;

  const factory PairingIntentEffect.connect(PairingIntent intent) =
      ConnectPairingEffect;

  const factory PairingIntentEffect.ignore() = IgnorePairingIntentEffect;
}

final class ApplyPairingImportEffect extends PairingIntentEffect {
  const ApplyPairingImportEffect(this.import) : super._();

  final ImportedPairingIntent import;
}

final class RequestPairingConfirmationEffect extends PairingIntentEffect {
  const RequestPairingConfirmationEffect(this.import) : super._();

  final ImportedPairingIntent import;
}

final class ConnectPairingEffect extends PairingIntentEffect {
  const ConnectPairingEffect(this.intent) : super._();

  final PairingIntent intent;
}

final class IgnorePairingIntentEffect extends PairingIntentEffect {
  const IgnorePairingIntentEffect() : super._();
}
