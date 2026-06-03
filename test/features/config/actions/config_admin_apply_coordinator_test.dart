import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/features/config/actions/config_admin_apply_coordinator.dart';
import 'package:navivox/features/config/apply/config_apply_flow_model.dart';

void main() {
  const coordinator = ConfigAdminApplyCoordinator();

  test('builds backend config changes from draft flow', () {
    final flow = ConfigApplyFlowModel(
      changes: [
        ConfigDraftChange(
          path: 'providers.default',
          label: 'Default provider',
          oldDisplayValue: 'openai',
          newDisplayValue: 'anthropic',
          applyValue: 'anthropic',
          isSecret: false,
          requiresConfirmation: false,
          restartRequired: false,
        ),
      ],
    );

    final changes = coordinator.changesFromFlow(flow);

    expect(changes, hasLength(1));
    expect(changes.single.key, 'providers.default');
    expect(changes.single.value, 'anthropic');
  });

  test('validation failure uses first backend error message', () {
    final effect = coordinator.afterValidation(
      const NavivoxConfigAdminResponse(
        action: 'validate',
        valid: false,
        errors: [
          NavivoxConfigAdminFieldError(
            key: 'navivox.exposure_mode',
            code: 'unsafe',
            message: 'Public exposure requires confirmation.',
          ),
        ],
      ),
    );

    expect(effect, isA<ShowConfigAdminApplyErrorEffect>());
    expect(
      (effect as ShowConfigAdminApplyErrorEffect).message,
      'Public exposure requires confirmation.',
    );
  });

  test('diff failure and rejected apply produce explicit errors', () {
    final diff = coordinator.afterDiff(
      const NavivoxConfigAdminResponse(action: 'diff', valid: false),
    );
    final applied = coordinator.afterApply(
      const NavivoxConfigAdminResponse(
        action: 'apply',
        valid: true,
        applied: false,
      ),
    );

    expect(
      (diff as ShowConfigAdminApplyErrorEffect).message,
      'Config diff failed.',
    );
    expect(
      (applied as ShowConfigAdminApplyErrorEffect).message,
      'Config apply was not accepted by Gormes.',
    );
  });

  test(
    'successful validation continues and successful apply marks applied',
    () {
      final validation = coordinator.afterValidation(
        const NavivoxConfigAdminResponse(action: 'validate', valid: true),
      );
      final response = const NavivoxConfigAdminResponse(
        action: 'apply',
        valid: true,
        applied: true,
      );
      final applied = coordinator.afterApply(response);

      expect(validation, isA<ContinueConfigAdminApplyEffect>());
      expect(applied, isA<MarkConfigAdminAppliedEffect>());
      expect((applied as MarkConfigAdminAppliedEffect).response, response);
    },
  );
}
