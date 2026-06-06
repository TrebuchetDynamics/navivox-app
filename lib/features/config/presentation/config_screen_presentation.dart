import '../../../core/channel/navivox_channel.dart';
import '../../../shared/presentation/profile_contact_scope_presentation.dart';
import '../apply/config_apply_flow_model.dart';
import '../apply/config_apply_presentation.dart';
import '../form/config_draft_session.dart';
import '../form/config_form_model.dart';
import 'config_section_presentation.dart';

class ConfigScreenPresentation {
  const ConfigScreenPresentation._({
    required this.scope,
    required this.configReadiness,
    required this.sections,
    required this.applyFlow,
    required this.applyPresentation,
    required this.isEmpty,
    this.missingSectionId,
  });

  factory ConfigScreenPresentation.fromState({
    required NavivoxChannelState state,
    required ConfigDraftSession draftSession,
    String? sectionId,
    bool? configAdminAvailable,
    bool? configAdminSupported,
    bool configAdminLoadFailed = false,
    bool configAdminChecking = false,
  }) {
    final form = ConfigFormModel.fromSchema(
      schema: state.configSchema,
      values: state.configValues,
    );
    final isEmpty = form.rows.isEmpty;
    final effectiveConfigAdminAvailable = configAdminAvailable ?? !isEmpty;
    final effectiveConfigAdminSupported =
        configAdminSupported ?? effectiveConfigAdminAvailable;
    final sectionSelection = form.selectSection(sectionId);
    final applyFlow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: draftSession.draftValues,
      validationSnapshot: state.configDiff,
    );
    final selectedSections = isEmpty || sectionSelection.isMissing
        ? const <ConfigFormSection>[]
        : sectionSelection.sections;

    return ConfigScreenPresentation._(
      scope: ProfileContactScopePresentation(
        activeServer: state.activeServer,
        activeServerId: state.activeServerId,
        activeProfile: state.activeProfileContact,
      ),
      configReadiness: ConfigReadinessPresentation.fromState(
        checking: configAdminChecking,
        supported: effectiveConfigAdminSupported,
        available: effectiveConfigAdminAvailable,
        loadFailed: configAdminLoadFailed,
        hasSchemaRows: !isEmpty,
      ),
      sections: selectedSections
          .map(
            (section) => ConfigSectionPresentation.fromSection(
              section,
              applyFlow: applyFlow,
              editingField: draftSession.editingField,
            ),
          )
          .toList(growable: false),
      applyFlow: applyFlow,
      applyPresentation: ConfigApplyPresentation.fromFlow(applyFlow),
      isEmpty: isEmpty,
      missingSectionId: isEmpty ? null : sectionSelection.missingId,
    );
  }

  final ProfileContactScopePresentation scope;
  final ConfigReadinessPresentation configReadiness;
  final List<ConfigSectionPresentation> sections;
  final ConfigApplyFlowModel applyFlow;
  final ConfigApplyPresentation applyPresentation;
  final bool isEmpty;
  final String? missingSectionId;

  bool get isMissingSection => missingSectionId != null;

  String get missingSectionMessage =>
      'Config section not found: $missingSectionId';

  bool get showPendingChanges => applyPresentation.hasChanges;
}

enum ConfigReadinessStatus {
  checking,
  ready,
  unsupported,
  loadFailed,
  emptySchema,
}

class ConfigReadinessPresentation {
  const ConfigReadinessPresentation._({required this.status});

  factory ConfigReadinessPresentation.fromState({
    required bool checking,
    required bool supported,
    required bool available,
    required bool loadFailed,
    required bool hasSchemaRows,
  }) {
    if (checking) {
      return const ConfigReadinessPresentation._(
        status: ConfigReadinessStatus.checking,
      );
    }
    if (!supported) {
      return const ConfigReadinessPresentation._(
        status: ConfigReadinessStatus.unsupported,
      );
    }
    if (loadFailed || !available) {
      return const ConfigReadinessPresentation._(
        status: ConfigReadinessStatus.loadFailed,
      );
    }
    if (!hasSchemaRows) {
      return const ConfigReadinessPresentation._(
        status: ConfigReadinessStatus.emptySchema,
      );
    }
    return const ConfigReadinessPresentation._(
      status: ConfigReadinessStatus.ready,
    );
  }

  final ConfigReadinessStatus status;

  String get title => 'Config readiness';

  String get statusLabel => switch (status) {
    ConfigReadinessStatus.checking => 'Checking config admin',
    ConfigReadinessStatus.ready => 'Config admin ready',
    ConfigReadinessStatus.unsupported => 'Config admin unsupported',
    ConfigReadinessStatus.loadFailed => 'Config admin load failed',
    ConfigReadinessStatus.emptySchema => 'Config schema empty',
  };

  String get message => switch (status) {
    ConfigReadinessStatus.checking =>
      'Checking whether Gormes can provide config-admin for this gateway.',
    ConfigReadinessStatus.ready =>
      'Gormes config-admin is loaded for this scope. Secrets stay redacted and changes require validation.',
    ConfigReadinessStatus.unsupported =>
      'This gateway does not advertise Gormes config-admin. Chat and voice may still work.',
    ConfigReadinessStatus.loadFailed =>
      'Gormes advertised config-admin, but Navivox could not load the schema and current values.',
    ConfigReadinessStatus.emptySchema =>
      'Gormes config-admin loaded, but it did not return editable config fields for this scope.',
  };

  String get refreshLabel => 'Refresh config';

  String get openGatewayLabel => 'Open gateway';

  bool get canRefresh => status != ConfigReadinessStatus.checking;
}
