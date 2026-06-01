import '../../../form/config_form_model.dart';
import '../../validation/config_validation_state.dart';
import '../change/config_draft_change.dart';

class ConfigApplyFlowModel {
  ConfigApplyFlowModel({
    required List<ConfigDraftChange> changes,
    List<String> globalValidationMessages = const [],
    ConfigValidationState? validation,
  }) : changes = List.unmodifiable(changes),
       globalValidationMessages = List.unmodifiable(globalValidationMessages),
       _validation = validation ?? ConfigValidationState.fromSnapshot(null);

  factory ConfigApplyFlowModel.fromDraft({
    required ConfigFormModel form,
    required Map<String, Object?> draftValues,
    Map<String, Object?>? validationSnapshot,
  }) {
    final validation = ConfigValidationState.fromSnapshot(validationSnapshot);
    return ConfigApplyFlowModel(
      changes: _draftChangesFromRows(
        rows: form.rows,
        draftValues: draftValues,
        validation: validation,
      ),
      globalValidationMessages: validation.globalMessages,
      validation: validation,
    );
  }

  final List<ConfigDraftChange> changes;
  final List<String> globalValidationMessages;
  final ConfigValidationState _validation;

  bool get hasPendingChanges => changes.isNotEmpty;

  bool get hasInvalidChanges =>
      globalValidationMessages.isNotEmpty ||
      _validation.hasFieldErrors ||
      changes.any((change) => change.isInvalid);

  bool get canApply => hasPendingChanges && !hasInvalidChanges;

  bool get requiresConfirmation =>
      changes.any((change) => change.requiresConfirmation);

  List<String> validationMessagesFor(String path) {
    final validationMessages = _validation.messagesFor(path);
    if (validationMessages.isNotEmpty) return validationMessages;
    return changes
        .where((change) => change.path == path)
        .expand((change) => change.validationMessages)
        .toList(growable: false);
  }
}

List<ConfigDraftChange> _draftChangesFromRows({
  required Iterable<ConfigFormRow> rows,
  required Map<String, Object?> draftValues,
  required ConfigValidationState validation,
}) {
  final changes = <ConfigDraftChange>[];
  for (final row in rows) {
    if (!draftValues.containsKey(row.field)) continue;
    final change = ConfigDraftChange.fromRow(
      row,
      draftValues[row.field],
      validation.messagesFor(row.field),
    );
    if (change != null) changes.add(change);
  }
  return changes;
}
