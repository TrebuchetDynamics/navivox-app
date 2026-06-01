import '../../shared/config_value_display.dart';
import '../editing/config_edit_text.dart';
import 'config_edit_value_coercion.dart';
import 'config_form_field_type.dart';
import 'config_form_schema_row.dart';
import 'config_form_schema_wire.dart';

export 'config_form_field_type.dart';

class ConfigFormModel {
  const ConfigFormModel({required this.rows, required this.sections});

  factory ConfigFormModel.fromSchema({
    required Map<String, Object?>? schema,
    required Map<String, Object?> values,
  }) {
    final rawFields = schema?['fields'];
    if (rawFields is! List) {
      return const ConfigFormModel(rows: [], sections: []);
    }

    final rows = <ConfigFormRow>[];
    for (final raw in rawFields) {
      final candidate = ConfigFormSchemaRowCandidate.fromRaw(
        raw: raw,
        values: values,
      );
      if (candidate == null) continue;
      rows.add(ConfigFormRow.fromSchemaCandidate(candidate));
    }
    return ConfigFormModel(
      rows: rows,
      sections: _buildSections(schema?['sections'], rows),
    );
  }

  final List<ConfigFormRow> rows;
  final List<ConfigFormSection> sections;

  ConfigSectionSelection selectSection(String? sectionId) {
    final id = sectionId?.trim();
    if (id == null || id.isEmpty) {
      return ConfigSectionSelection(sections: sections);
    }
    for (final section in sections) {
      if (section.id == id) {
        return ConfigSectionSelection(sections: [section], requestedId: id);
      }
    }
    return ConfigSectionSelection(
      sections: const [],
      requestedId: id,
      missingId: id,
    );
  }

  static List<ConfigFormSection> _buildSections(
    Object? rawSections,
    List<ConfigFormRow> rows,
  ) {
    if (rows.isEmpty) return const [];
    if (rawSections is! List) {
      return [ConfigFormSection.general(rows: rows)];
    }

    final rowsByField = {for (final row in rows) row.field: row};
    final usedFields = <String>{};
    final sections = <ConfigFormSection>[];

    for (final raw in rawSections) {
      if (raw is! Map) continue;
      final sectionRows = <ConfigFormRow>[];
      for (final field in configFormSectionFieldRefsFromSchemaMap(raw)) {
        final row = rowsByField[field];
        if (row == null || usedFields.contains(row.field)) continue;
        sectionRows.add(row);
        usedFields.add(row.field);
      }
      if (sectionRows.isEmpty) continue;
      final id = configFormSectionIdFromSchema(
        raw,
        'section-${sections.length + 1}',
      );
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
        sections.isEmpty
            ? ConfigFormSection.general(rows: otherRows)
            : ConfigFormSection.other(rows: otherRows),
      );
    }
    return sections;
  }
}

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
  const ConfigFormSection({
    required this.id,
    required this.label,
    required this.rows,
    this.description,
  });

  const ConfigFormSection.general({required this.rows})
    : id = 'general',
      label = 'General config',
      description = null;

  const ConfigFormSection.other({required this.rows})
    : id = 'other',
      label = 'Other config',
      description = null;

  final String id;
  final String label;
  final String? description;
  final List<ConfigFormRow> rows;
}

class ConfigFormRow {
  factory ConfigFormRow.fromSchemaCandidate(
    ConfigFormSchemaRowCandidate candidate,
  ) {
    return ConfigFormRow(
      field: candidate.field,
      label: candidate.label,
      type: candidate.type,
      required: candidate.required,
      restartRequired: candidate.restartRequired,
      riskLevel: candidate.riskLevel,
      requiresConfirmation: candidate.requiresConfirmation,
      rawValue: candidate.rawValue,
      allowedValues: candidate.allowedValues,
      actions: candidate.actions,
      reloadMode: candidate.reloadMode,
    );
  }

  const ConfigFormRow({
    required this.field,
    required this.label,
    required this.type,
    required this.required,
    required this.restartRequired,
    required this.riskLevel,
    required this.requiresConfirmation,
    required this.rawValue,
    this.allowedValues = const [],
    this.actions = const [],
    this.reloadMode = '',
  });

  final String field;
  final String label;
  final ConfigFormFieldType type;
  final bool required;
  final bool restartRequired;
  final String riskLevel;
  final bool requiresConfirmation;
  final Object? rawValue;
  final List<String> allowedValues;
  final List<String> actions;
  final String reloadMode;

  bool get isSecret => type == ConfigFormFieldType.secret;

  Object? get plainValue => _plainValue(rawValue);

  String get displayValue {
    if (isSecret) return configSecretDisplayValue(rawValue);
    return configDisplayValue(_plainValue(rawValue));
  }

  String get editInitialValue {
    if (isSecret) return '';
    return configEditTextFromValue(_plainValue(rawValue));
  }

  Object? coerceEditValue(String raw) =>
      coerceConfigEditValue(raw: raw, type: type, isSecret: isSecret);

  static Object? _plainValue(Object? rawValue) {
    if (rawValue is Map && rawValue.containsKey('value')) {
      return rawValue['value'];
    }
    return rawValue;
  }
}
