import 'config_validation_issues.dart';
import 'config_validation_snapshot_wire.dart';

class ConfigValidationState {
  const ConfigValidationState(this._issues);

  factory ConfigValidationState.fromSnapshot(Map<String, Object?>? snapshot) {
    if (snapshot == null) {
      return ConfigValidationState(ConfigValidationIssues());
    }
    final wire = ConfigValidationSnapshotWire(snapshot);
    return ConfigValidationState(
      ConfigValidationIssues.fromSnapshotParts(
        validationErrors: wire.validationErrors,
        genericErrors: wire.genericErrors,
        fieldErrors: wire.fieldErrors,
      ),
    );
  }

  final ConfigValidationIssues _issues;

  bool get hasGlobalErrors => _issues.hasGlobalErrors;

  bool get hasFieldErrors => _issues.hasFieldErrors;

  bool get hasAnyErrors => _issues.hasAnyErrors;

  List<String> get globalMessages => _issues.globalMessages;

  List<String> messagesFor(String path) => _issues.messagesFor(path);
}
