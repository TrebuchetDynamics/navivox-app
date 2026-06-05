import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/profiles/presentation/profile_seed_presentation.dart';

void main() {
  const presentation = ProfileSeedPresentation();

  test('exposes stable profile seed form copy', () {
    expect(presentation.title, 'Create from seed');
    expect(presentation.seedFieldLabel, 'Profile seed');
    expect(presentation.workspaceRootFieldHelper, contains('sent to Gormes'));
    expect(
      presentation.noWorkspaceConfirmationSubtitle,
      contains('suggested workspaces are not granted'),
    );
  });

  test('builds draft summary from gateway draft map', () {
    final summary = presentation.draftSummary(const {
      'provider_model_state': {'status': 'unconfigured'},
      'generation_source': 'template',
      'evidence': ['template_fallback', 'workspace_confirmation_required'],
    });

    expect(summary.generationSourceLine, 'generation_source=template');
    expect(summary.providerStatusLine, 'Provider status: unconfigured');
    expect(
      summary.evidenceLine,
      'Evidence: template_fallback, workspace_confirmation_required',
    );
  });

  test('builds workspace suggestion rows without granting workspaces', () {
    final suggestions = presentation.workspaceSuggestions(const {
      'workspace_root_suggestions': [
        {
          'label': 'Mineru workspace',
          'purpose': 'Operator-confirmed workspace for Mineru',
          'requires_confirmation': true,
        },
        {
          'label': 'Docs',
          'purpose': 'Reference only',
          'requires_confirmation': false,
        },
      ],
    });

    expect(suggestions, hasLength(2));
    expect(suggestions.first.label, 'Mineru workspace');
    expect(
      suggestions.first.subtitle,
      'Operator-confirmed workspace for Mineru (requires confirmation)',
    );
    expect(suggestions.last.subtitle, 'Reference only (informational)');
  });
}
