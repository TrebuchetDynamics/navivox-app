import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../apply/config_apply_flow_model.dart';

/// Coordinates config-admin validation/diff/apply outcomes into typed UI effects.
///
/// The screen still owns async gateway calls, dialogs, draft state, and rendering.
/// This module keeps backend result interpretation and change construction out of
/// the widget adapter.
final class ConfigAdminApplyCoordinator {
  const ConfigAdminApplyCoordinator();

  List<NavivoxConfigAdminChange> changesFromFlow(ConfigApplyFlowModel flow) {
    return flow.changes
        .map(
          (change) => NavivoxConfigAdminChange(
            key: change.path,
            value: change.applyValue,
          ),
        )
        .toList(growable: false);
  }

  ConfigAdminApplyEffect afterValidation(
    NavivoxConfigAdminResponse validation,
  ) {
    if (validation.valid) return const ConfigAdminApplyEffect.continueFlow();
    return ConfigAdminApplyEffect.showError(
      _validationErrorMessage(validation),
    );
  }

  ConfigAdminApplyEffect afterDiff(NavivoxConfigAdminResponse diff) {
    if (diff.valid) return const ConfigAdminApplyEffect.continueFlow();
    return const ConfigAdminApplyEffect.showError('Config diff failed.');
  }

  ConfigAdminApplyEffect afterApply(NavivoxConfigAdminResponse applied) {
    if (!applied.applied) {
      return const ConfigAdminApplyEffect.showError(
        'Config apply was not accepted by Gormes.',
      );
    }
    return ConfigAdminApplyEffect.markApplied(applied);
  }

  ConfigAdminApplyEffect requestFailed() {
    return const ConfigAdminApplyEffect.showError(
      'Config admin request failed.',
    );
  }

  String _validationErrorMessage(NavivoxConfigAdminResponse validation) {
    for (final error in validation.errors) {
      if (error.message.trim().isNotEmpty) return error.message.trim();
    }
    return 'Config validation failed.';
  }
}

sealed class ConfigAdminApplyEffect {
  const ConfigAdminApplyEffect._();

  const factory ConfigAdminApplyEffect.continueFlow() =
      ContinueConfigAdminApplyEffect;

  const factory ConfigAdminApplyEffect.showError(String message) =
      ShowConfigAdminApplyErrorEffect;

  const factory ConfigAdminApplyEffect.markApplied(
    NavivoxConfigAdminResponse response,
  ) = MarkConfigAdminAppliedEffect;
}

final class ContinueConfigAdminApplyEffect extends ConfigAdminApplyEffect {
  const ContinueConfigAdminApplyEffect() : super._();
}

final class ShowConfigAdminApplyErrorEffect extends ConfigAdminApplyEffect {
  const ShowConfigAdminApplyErrorEffect(this.message) : super._();

  final String message;
}

final class MarkConfigAdminAppliedEffect extends ConfigAdminApplyEffect {
  const MarkConfigAdminAppliedEffect(this.response) : super._();

  final NavivoxConfigAdminResponse response;
}
