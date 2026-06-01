import '../model/config_apply_flow_model.dart';
import '../model/config_draft_change.dart';

class ConfigApplyPresentation {
  ConfigApplyPresentation({
    required this.changes,
    required this.canApply,
    required this.requiresConfirmation,
    List<String> globalValidationMessages = const [],
    this.title = 'Pending config changes',
    this.applyButtonLabel = 'Apply pending changes',
    this.confirmationTitle = 'Confirm high-risk config changes',
    this.confirmationIntro = 'Review before/after values before applying.',
  }) : globalValidationMessages = List.unmodifiable(globalValidationMessages);

  factory ConfigApplyPresentation.fromFlow(ConfigApplyFlowModel flow) {
    return ConfigApplyPresentation(
      changes: flow.changes
          .map(ConfigApplyChangePresentation.fromChange)
          .toList(growable: false),
      canApply: flow.canApply,
      requiresConfirmation: flow.requiresConfirmation,
      globalValidationMessages: flow.globalValidationMessages,
    );
  }

  final String title;
  final String applyButtonLabel;
  final String confirmationTitle;
  final String confirmationIntro;
  final List<ConfigApplyChangePresentation> changes;
  final List<String> globalValidationMessages;
  final bool canApply;
  final bool requiresConfirmation;

  bool get hasChanges => changes.isNotEmpty;

  bool get hasGlobalValidationMessages => globalValidationMessages.isNotEmpty;
}

class ConfigApplyChangePresentation {
  const ConfigApplyChangePresentation({
    required this.summaryLabel,
    required this.restartRequired,
    required this.validationMessages,
  });

  factory ConfigApplyChangePresentation.fromChange(ConfigDraftChange change) {
    return ConfigApplyChangePresentation(
      summaryLabel: change.summaryLabel,
      restartRequired: change.restartRequired,
      validationMessages: List.unmodifiable(change.validationMessages),
    );
  }

  final String summaryLabel;
  final bool restartRequired;
  final List<String> validationMessages;

  String? get restartLabel => restartRequired ? 'Restart required' : null;

  bool get hasRestartLabel => restartLabel != null;

  bool get hasValidationMessages => validationMessages.isNotEmpty;
}
