import '../../../core/protocol/navivox_json.dart';

final class ProfileSeedPresentation {
  const ProfileSeedPresentation();

  String get title => 'Create from seed';
  String get instructions =>
      'Gormes drafts profile config from your text. Navivox never writes TOML or grants workspace roots directly.';
  String get seedFieldLabel => 'Profile seed';
  String get seedFieldHint => 'work on mineru repo';
  String get generateDraftLabel => 'Generate draft';
  String get profileIdFieldLabel => 'Profile ID';
  String get displayNameFieldLabel => 'Display name';
  String get instructionsFieldLabel => 'Instructions';
  String get providerFieldLabel => 'Provider';
  String get modelFieldLabel => 'Model';
  String get toolPolicyFieldLabel => 'Tool policy';
  String get voiceMetadataFieldLabel => 'Voice metadata';
  String get workspaceSuggestionsTitle => 'Workspace suggestions';
  String get workspaceRootFieldLabel => 'Workspace root path';
  String get workspaceRootFieldHint => '/absolute/path/to/workspace';
  String get workspaceRootFieldHelper =>
      'Only paths you type here are sent to Gormes on apply.';
  String get noWorkspaceConfirmationTitle => 'Continue without workspace roots';
  String get noWorkspaceConfirmationSubtitle =>
      'I understand suggested workspaces are not granted unless I type a path.';
  String get applyLabel => 'Apply through Gormes';
  String get emptyWorkspaceSuggestions =>
      'No workspace suggestions returned by Gormes.';

  ProfileSeedDraftSummaryPresentation draftSummary(Map<String, Object?> draft) {
    final providerState = navivoxMapFieldFromJson(
      draft,
      'provider_model_state',
    );
    final generationSource = navivoxStringFieldFromJson(
      draft,
      'generation_source',
    );
    final evidence = navivoxStringListFieldFromJson(draft, 'evidence');
    return ProfileSeedDraftSummaryPresentation(
      generationSourceLine: 'generation_source=$generationSource',
      providerStatusLine:
          'Provider status: ${navivoxStringFieldFromJson(providerState, 'status')}',
      evidenceLine: evidence.isEmpty
          ? null
          : 'Evidence: ${evidence.join(', ')}',
    );
  }

  List<ProfileSeedWorkspaceSuggestionPresentation> workspaceSuggestions(
    Map<String, Object?> draft,
  ) {
    return navivoxListFieldFromJson(draft, 'workspace_root_suggestions')
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .map((suggestion) {
          final confirmation =
              navivoxStrictBoolFromJson(suggestion['requires_confirmation'])
              ? 'requires confirmation'
              : 'informational';
          return ProfileSeedWorkspaceSuggestionPresentation(
            label: navivoxStringFieldFromJson(suggestion, 'label'),
            subtitle:
                '${navivoxStringFieldFromJson(suggestion, 'purpose')} ($confirmation)',
          );
        })
        .toList(growable: false);
  }
}

final class ProfileSeedDraftSummaryPresentation {
  const ProfileSeedDraftSummaryPresentation({
    required this.generationSourceLine,
    required this.providerStatusLine,
    this.evidenceLine,
  });

  final String generationSourceLine;
  final String providerStatusLine;
  final String? evidenceLine;
}

final class ProfileSeedWorkspaceSuggestionPresentation {
  const ProfileSeedWorkspaceSuggestionPresentation({
    required this.label,
    required this.subtitle,
  });

  final String label;
  final String subtitle;
}
