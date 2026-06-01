import 'config_form_schema_row.dart';

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
  final candidates = <ConfigFormSchemaRowCandidate>[];
  final seenFields = <String>{};
  for (final raw in rawFields) {
    final candidate = ConfigFormSchemaRowCandidate.fromRaw(
      raw: raw,
      values: values,
    );
    if (candidate == null) continue;
    if (!seenFields.add(candidate.field)) continue;
    candidates.add(candidate);
  }
  return candidates;
}
