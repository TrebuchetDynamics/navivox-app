import '../../form/config_wire_fields.dart';
import '../../form/wire/config_form_wire_contract.dart';

enum ConfigValidationIssueSource {
  validationErrors,
  genericErrors,
  fieldErrors,
}

class ConfigValidationIssueCandidate {
  const ConfigValidationIssueCandidate({
    required this.source,
    required this.message,
    this.path,
  });

  final ConfigValidationIssueSource source;
  final String message;
  final String? path;

  bool get isGlobal => path == null;
}

/// Replays validation snapshot ingestion in the exact order used for display.
///
/// Keeping this pure candidate stream separate from de-duplication makes dropped
/// or reclassified errors easier to characterize from captured gateway payloads:
/// field-scoped validation errors are read first, then generic errors, then the
/// field-error map.
Iterable<ConfigValidationIssueCandidate>
configValidationIssueCandidatesFromSnapshotParts({
  required Object? validationErrors,
  required Object? genericErrors,
  required Object? fieldErrors,
}) sync* {
  yield* _validationErrorListCandidates(validationErrors);
  yield* _genericErrorCandidates(genericErrors);
  yield* _fieldErrorMapCandidates(fieldErrors);
}

class ConfigValidationIssues {
  ConfigValidationIssues({
    Map<String, List<String>> messagesByPath = const {},
    List<String> globalMessages = const [],
  }) : messagesByPath = Map<String, List<String>>.unmodifiable(
         messagesByPath.map(
           (path, messages) =>
               MapEntry(path, List<String>.unmodifiable(messages)),
         ),
       ),
       globalMessages = List.unmodifiable(globalMessages);

  factory ConfigValidationIssues.fromSnapshotParts({
    required Object? validationErrors,
    required Object? genericErrors,
    required Object? fieldErrors,
  }) {
    final builder = _ConfigValidationIssuesBuilder();
    for (final candidate in configValidationIssueCandidatesFromSnapshotParts(
      validationErrors: validationErrors,
      genericErrors: genericErrors,
      fieldErrors: fieldErrors,
    )) {
      builder.addCandidate(candidate);
    }
    return builder.build();
  }

  final Map<String, List<String>> messagesByPath;
  final List<String> globalMessages;

  bool get hasGlobalErrors => globalMessages.isNotEmpty;

  bool get hasFieldErrors =>
      messagesByPath.values.any((messages) => messages.isNotEmpty);

  bool get hasAnyErrors => hasGlobalErrors || hasFieldErrors;

  List<String> messagesFor(String path) {
    return List.unmodifiable(messagesByPath[path] ?? const []);
  }
}

class _ConfigValidationIssuesBuilder {
  final Map<String, List<String>> _messagesByPath = {};
  final List<String> _globalMessages = [];

  void addCandidate(ConfigValidationIssueCandidate candidate) {
    final path = candidate.path;
    if (path == null) {
      _appendGlobalMessage(candidate.message);
    } else {
      _appendPathMessage(path: path, message: candidate.message);
    }
  }

  ConfigValidationIssues build() {
    return ConfigValidationIssues(
      messagesByPath: _messagesByPath,
      globalMessages: _globalMessages,
    );
  }

  void _appendPathMessage({required String path, required String message}) {
    final pathMessages = _messagesByPath.putIfAbsent(path, () => []);
    if (pathMessages.contains(message)) return;
    pathMessages.add(message);
  }

  void _appendGlobalMessage(String message) {
    if (_globalMessages.contains(message)) return;
    _globalMessages.add(message);
  }
}

Iterable<ConfigValidationIssueCandidate> _validationErrorListCandidates(
  Object? rawErrors,
) sync* {
  if (rawErrors is! List) return;
  for (final raw in rawErrors) {
    if (raw is! Map) continue;
    final message = configFormValidationMessageFromWire(raw);
    if (message == null) continue;
    yield ConfigValidationIssueCandidate(
      source: ConfigValidationIssueSource.validationErrors,
      path: configFormValidationPathFromWire(raw),
      message: message,
    );
  }
}

Iterable<ConfigValidationIssueCandidate> _genericErrorCandidates(
  Object? rawErrors,
) sync* {
  if (rawErrors is List) {
    for (final raw in rawErrors) {
      yield* _genericErrorCandidate(raw);
    }
    return;
  }
  yield* _genericErrorCandidate(rawErrors);
}

Iterable<ConfigValidationIssueCandidate> _genericErrorCandidate(
  Object? raw,
) sync* {
  if (raw is Map) {
    final message = configFormValidationMessageFromWire(raw);
    if (message == null) return;
    yield ConfigValidationIssueCandidate(
      source: ConfigValidationIssueSource.genericErrors,
      path: configFormValidationPathFromWire(raw),
      message: message,
    );
    return;
  }

  final message = _validationIssueMessageFrom(raw);
  if (message == null) return;
  yield ConfigValidationIssueCandidate(
    source: ConfigValidationIssueSource.genericErrors,
    message: message,
  );
}

Iterable<ConfigValidationIssueCandidate> _fieldErrorMapCandidates(
  Object? rawErrors,
) sync* {
  if (rawErrors is! Map) return;
  for (final entry in rawErrors.entries) {
    final path = configWireString(entry.key);
    if (path == null) continue;
    for (final message in _validationIssueMessagesFrom(entry.value)) {
      yield ConfigValidationIssueCandidate(
        source: ConfigValidationIssueSource.fieldErrors,
        path: path,
        message: message,
      );
    }
  }
}

List<String> _validationIssueMessagesFrom(Object? raw) {
  if (raw is List) {
    return raw
        .map(_validationIssueMessageFrom)
        .nonNulls
        .toList(growable: false);
  }
  final message = _validationIssueMessageFrom(raw);
  return message == null ? const [] : [message];
}

String? _validationIssueMessageFrom(Object? raw) {
  if (raw is Map) return configFormValidationMessageFromWire(raw);
  return configWireString(raw);
}
