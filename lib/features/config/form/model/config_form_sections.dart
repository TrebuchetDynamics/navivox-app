import 'config_form_model.dart';
import 'config_form_schema_wire.dart';

class ConfigSectionSelection {
  const ConfigSectionSelection({
    required this.sections,
    this.requestedId,
    this.missingId,
  });

  final List<ConfigFormSection> sections;
  final String? requestedId;
  final String? missingId;

  bool get isFiltered => requestedId != null;

  bool get isMissing => missingId != null;
}

class ConfigFormSection {
  ConfigFormSection({
    required this.id,
    required this.label,
    required List<ConfigFormRow> rows,
    this.description,
  }) : rows = List.unmodifiable(rows);

  ConfigFormSection.general({required List<ConfigFormRow> rows})
    : id = 'general',
      label = 'General config',
      description = null,
      rows = List.unmodifiable(rows);

  ConfigFormSection.other({required List<ConfigFormRow> rows})
    : id = 'other',
      label = 'Other config',
      description = null,
      rows = List.unmodifiable(rows);

  final String id;
  final String label;
  final String? description;
  final List<ConfigFormRow> rows;
}

List<ConfigFormSection> buildConfigFormSections({
  required Object? rawSections,
  required List<ConfigFormRow> rows,
}) {
  if (rows.isEmpty) return const [];
  if (rawSections is! List) {
    return [ConfigFormSection.general(rows: rows)];
  }

  final rowsByField = {for (final row in rows) row.field: row};
  final usedFields = <String>{};
  final usedSectionIds = <String>{};
  final sections = <ConfigFormSection>[];

  for (final raw in rawSections) {
    if (raw is! Map) continue;
    final sectionRows = _sectionRowsFromFirstUsefulFieldRefCandidate(
      rawSection: raw,
      rowsByField: rowsByField,
      usedFields: usedFields,
    );
    if (sectionRows.isEmpty) continue;
    final fallbackId = 'section-${sections.length + 1}';
    final requestedId = configFormSectionIdFromSchema(raw, fallbackId);
    final id = _uniqueSectionId(requestedId, usedSectionIds);
    sections.add(
      ConfigFormSection(
        id: id,
        label: configFormSectionLabelFromSchema(raw, id),
        description: configFormSectionDescriptionFromSchema(raw),
        rows: sectionRows,
      ),
    );
  }

  final otherRows = rows
      .where((row) => !usedFields.contains(row.field))
      .toList(growable: false);
  if (otherRows.isNotEmpty) {
    sections.add(
      _unsectionedRowsSection(
        rows: otherRows,
        hasServerSections: sections.isNotEmpty,
        usedSectionIds: usedSectionIds,
      ),
    );
  }
  return sections;
}

List<ConfigFormRow> _sectionRowsFromFirstUsefulFieldRefCandidate({
  required Map rawSection,
  required Map<String, ConfigFormRow> rowsByField,
  required Set<String> usedFields,
}) {
  for (final candidate in configFormSectionFieldRefAliasCandidates(
    rawSection,
  )) {
    final plan = configFormSectionRowsCandidatePlan(
      rawFieldRefs: candidate,
      rowsByField: rowsByField,
      usedFields: usedFields,
    );
    if (plan.rows.isEmpty) continue;
    usedFields.addAll(plan.rows.map((row) => row.field));
    return plan.rows;
  }
  return const [];
}

class ConfigFormSectionRowsCandidatePlan {
  ConfigFormSectionRowsCandidatePlan({
    required List<ConfigFormRow> rows,
    required this.skippedStaleRefs,
    required this.skippedDuplicateRefs,
  }) : rows = List.unmodifiable(rows);

  final List<ConfigFormRow> rows;
  final int skippedStaleRefs;
  final int skippedDuplicateRefs;
}

ConfigFormSectionRowsCandidatePlan configFormSectionRowsCandidatePlan({
  required Object? rawFieldRefs,
  required Map<String, ConfigFormRow> rowsByField,
  required Set<String> usedFields,
}) {
  final candidateRows = <ConfigFormRow>[];
  final seenCandidateFields = <String>{};
  var skippedStaleRefs = 0;
  var skippedDuplicateRefs = 0;

  for (final field in configFormSectionFieldRefsFromSchema(rawFieldRefs)) {
    final row = rowsByField[field];
    if (row == null || usedFields.contains(row.field)) {
      skippedStaleRefs += 1;
      continue;
    }
    if (!seenCandidateFields.add(row.field)) {
      skippedDuplicateRefs += 1;
      continue;
    }
    candidateRows.add(row);
  }

  return ConfigFormSectionRowsCandidatePlan(
    rows: candidateRows,
    skippedStaleRefs: skippedStaleRefs,
    skippedDuplicateRefs: skippedDuplicateRefs,
  );
}

ConfigFormSection _unsectionedRowsSection({
  required List<ConfigFormRow> rows,
  required bool hasServerSections,
  required Set<String> usedSectionIds,
}) {
  final fallbackId = hasServerSections ? 'other' : 'general';
  return ConfigFormSection(
    id: _uniqueSectionId(fallbackId, usedSectionIds),
    label: hasServerSections ? 'Other config' : 'General config',
    rows: rows,
  );
}

String _uniqueSectionId(String requestedId, Set<String> usedSectionIds) {
  if (usedSectionIds.add(requestedId)) return requestedId;
  var suffix = 2;
  while (true) {
    final candidate = '$requestedId-$suffix';
    if (usedSectionIds.add(candidate)) return candidate;
    suffix += 1;
  }
}
