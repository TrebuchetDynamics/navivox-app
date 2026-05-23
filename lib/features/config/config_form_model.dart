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
      if (raw is! Map) continue;
      final field = (raw['path'] ?? raw['name'])?.toString().trim();
      if (field == null || field.isEmpty) continue;
      final type = ConfigFormFieldType.fromWire(raw['type']?.toString());
      final secret =
          raw['secret'] == true || type == ConfigFormFieldType.secret;
      rows.add(
        ConfigFormRow(
          field: field,
          label: raw['label']?.toString().trim().isNotEmpty == true
              ? raw['label'].toString().trim()
              : field,
          type: secret ? ConfigFormFieldType.secret : type,
          required: raw['required'] == true,
          restartRequired: raw['restart_required'] == true,
          riskLevel:
              raw['risk_level']?.toString().trim().toLowerCase() ?? 'low',
          requiresConfirmation:
              raw['requires_confirmation'] == true ||
              raw['risk_level']?.toString().trim().toLowerCase() == 'high',
          rawValue: values[field],
        ),
      );
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
      for (final field in _sectionFieldRefs(raw['fields'])) {
        final row = rowsByField[field];
        if (row == null || usedFields.contains(row.field)) continue;
        sectionRows.add(row);
        usedFields.add(row.field);
      }
      if (sectionRows.isEmpty) continue;
      final id = _sectionText(raw['id']) ?? 'section-${sections.length + 1}';
      sections.add(
        ConfigFormSection(
          id: id,
          label: _sectionText(raw['label']) ?? id,
          description: _sectionText(raw['description']),
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

  static List<String> _sectionFieldRefs(Object? rawFields) {
    if (rawFields is! List) return const [];
    final refs = <String>[];
    for (final raw in rawFields) {
      final field = raw is Map ? raw['path'] ?? raw['name'] : raw;
      final text = field?.toString().trim();
      if (text != null && text.isNotEmpty) refs.add(text);
    }
    return refs;
  }

  static String? _sectionText(Object? raw) {
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
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

enum ConfigFormFieldType {
  string,
  number,
  integer,
  boolean,
  secret;

  factory ConfigFormFieldType.fromWire(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'number' => ConfigFormFieldType.number,
      'integer' => ConfigFormFieldType.integer,
      'boolean' => ConfigFormFieldType.boolean,
      'secret' => ConfigFormFieldType.secret,
      _ => ConfigFormFieldType.string,
    };
  }

  bool get isNumeric =>
      this == ConfigFormFieldType.number || this == ConfigFormFieldType.integer;
}

class ConfigFormRow {
  const ConfigFormRow({
    required this.field,
    required this.label,
    required this.type,
    required this.required,
    required this.restartRequired,
    required this.riskLevel,
    required this.requiresConfirmation,
    required this.rawValue,
  });

  final String field;
  final String label;
  final ConfigFormFieldType type;
  final bool required;
  final bool restartRequired;
  final String riskLevel;
  final bool requiresConfirmation;
  final Object? rawValue;

  bool get isSecret => type == ConfigFormFieldType.secret;

  Object? get plainValue => _plainValue(rawValue);

  String get displayValue {
    if (isSecret) return _secretDisplayValue(rawValue);
    final value = _plainValue(rawValue);
    if (value == null) return '—';
    return '$value';
  }

  String get editInitialValue {
    if (isSecret) return '';
    final value = _plainValue(rawValue);
    return value == null ? '' : '$value';
  }

  Object? coerceEditValue(String raw) {
    final text = raw.trim();
    if (isSecret) return text;
    return switch (type) {
      ConfigFormFieldType.number ||
      ConfigFormFieldType.integer => num.tryParse(text) ?? raw,
      ConfigFormFieldType.boolean => text.toLowerCase() == 'true',
      ConfigFormFieldType.string => raw,
      ConfigFormFieldType.secret => text,
    };
  }

  static Object? _plainValue(Object? rawValue) {
    if (rawValue is Map && rawValue.containsKey('value')) {
      return rawValue['value'];
    }
    return rawValue;
  }

  static String _secretDisplayValue(Object? rawValue) {
    if (rawValue == null) return 'Secret not set';
    if (rawValue is Map) {
      final status = rawValue['secret_status']?.toString().trim().toLowerCase();
      return switch (status) {
        'configured' || 'external' => 'Secret configured',
        'unset' => 'Secret not set',
        'unknown' => 'Secret status unknown',
        _ => 'Secret configured',
      };
    }
    return 'Secret configured';
  }
}
