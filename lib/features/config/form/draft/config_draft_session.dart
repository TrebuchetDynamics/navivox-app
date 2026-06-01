import '../../apply/config_apply_flow_model.dart';
import '../../apply/model/config_draft_value_equality.dart';
import '../presentation/config_field_presentation.dart';
import 'config_draft_edit_value.dart';

class ConfigDraftSession {
  const ConfigDraftSession({this.draftValues = const {}, this.editingField});

  final Map<String, Object?> draftValues;
  final String? editingField;

  bool isEditing(ConfigFieldPresentation field) => editingField == field.path;

  String editInitialValueFor(ConfigFieldPresentation field) {
    if (field.obscureText || !draftValues.containsKey(field.path)) {
      return field.editInitialValue;
    }
    return configDraftEditInitialValue(draftValues[field.path]);
  }

  ConfigDraftSession beginEditing(ConfigFieldPresentation field) {
    return ConfigDraftSession(
      draftValues: Map.unmodifiable(draftValues),
      editingField: field.path,
    );
  }

  ConfigDraftSession cancelEditing() {
    return ConfigDraftSession(draftValues: Map.unmodifiable(draftValues));
  }

  ConfigDraftSession stageEdit(ConfigFieldPresentation field, String rawText) {
    final value = field.coerceEditValue(rawText);
    final nextDraft = Map<String, Object?>.from(draftValues);
    if (field.clearsDraftFor(value)) {
      nextDraft.remove(field.path);
    } else {
      nextDraft[field.path] = value;
    }
    return ConfigDraftSession(draftValues: Map.unmodifiable(nextDraft));
  }

  ConfigDraftSession clearApplied(ConfigApplyFlowModel flow) {
    if (!flow.hasPendingChanges) return this;
    final nextDraft = Map<String, Object?>.from(draftValues);
    for (final change in flow.changes) {
      if (_draftValueStillMatchesApplied(
        draftValues: draftValues,
        path: change.path,
        appliedValue: change.applyValue,
      )) {
        nextDraft.remove(change.path);
      }
    }
    return ConfigDraftSession(
      draftValues: Map.unmodifiable(nextDraft),
      editingField: editingField,
    );
  }
}

bool _draftValueStillMatchesApplied({
  required Map<String, Object?> draftValues,
  required String path,
  required Object? appliedValue,
}) {
  return draftValues.containsKey(path) &&
      configDraftValuesEqual(draftValues[path], appliedValue);
}
