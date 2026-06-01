import 'config_form_schema_row.dart';

class ConfigFormSchemaRowCandidatePlan {
  ConfigFormSchemaRowCandidatePlan({
    required List<ConfigFormSchemaRowCandidate> candidates,
    required this.skippedInvalidRows,
    required this.skippedDuplicateRows,
  }) : candidates = List.unmodifiable(candidates);

  final List<ConfigFormSchemaRowCandidate> candidates;
  final int skippedInvalidRows;
  final int skippedDuplicateRows;

  int get acceptedRows => candidates.length;
}

/// Builds validated schema row candidates in the exact order they should appear
/// in the form model.
///
/// This keeps the schema ingestion decision points explicit: non-map/blank rows
/// are dropped, the first candidate for a field path wins, and values are
/// attached from the same path used for de-duplication.
List<ConfigFormSchemaRowCandidate> configFormSchemaRowCandidatesFromFields({
  required List rawFields,
  required Map<String, Object?> values,
}) {
  return configFormSchemaRowCandidatePlanFromFields(
    rawFields: rawFields,
    values: values,
  ).candidates;
}

/// Replays schema row ingestion with visibility into skipped candidates.
///
/// The form still consumes only [candidates], but tests and diagnostics can now
/// assert that invalid rows and duplicate field paths are intentionally dropped
/// instead of disappearing inside the model constructor.
ConfigFormSchemaRowCandidatePlan configFormSchemaRowCandidatePlanFromFields({
  required List rawFields,
  required Map<String, Object?> values,
}) {
  final candidates = <ConfigFormSchemaRowCandidate>[];
  final seenFields = <String>{};
  var skippedInvalidRows = 0;
  var skippedDuplicateRows = 0;

  for (final raw in rawFields) {
    final candidate = ConfigFormSchemaRowCandidate.fromRaw(
      raw: raw,
      values: values,
    );
    if (candidate == null) {
      skippedInvalidRows += 1;
      continue;
    }
    if (!seenFields.add(candidate.field)) {
      skippedDuplicateRows += 1;
      continue;
    }
    candidates.add(candidate);
  }

  return ConfigFormSchemaRowCandidatePlan(
    candidates: candidates,
    skippedInvalidRows: skippedInvalidRows,
    skippedDuplicateRows: skippedDuplicateRows,
  );
}
