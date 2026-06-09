part of '../parser.dart';

Iterable<_JsonConnectionImportFields> _jsonCandidateMaps(
  Map<dynamic, dynamic> decoded,
) sync* {
  final entries = decoded['entries'];
  final decodedPresence = _JsonConnectionImportFieldPresence.from(decoded);
  if (entries is! List) {
    yield _JsonConnectionImportFields(
      fields: decoded,
      hasExplicitConnectionFields: decodedPresence.hasUsableEndpointOrToken,
    );
    return;
  }

  var yieldedEntry = false;
  for (final fields in _entryCandidateMaps(decoded, entries)) {
    yieldedEntry = true;
    yield fields;
  }
  if (!yieldedEntry) {
    yield _JsonConnectionImportFields(
      fields: decoded,
      hasExplicitConnectionFields: decodedPresence.hasUsableEndpointOrToken,
    );
  }
}

Iterable<_JsonConnectionImportFields> _entryCandidateMaps(
  Map<dynamic, dynamic> decoded,
  List<dynamic> entries,
) sync* {
  for (final entry in entries) {
    if (entry is! Map) continue;
    yield _JsonConnectionImportFields(
      fields: _entryFieldsWithJsonDefaults(decoded, entry),
      hasExplicitConnectionFields: _JsonConnectionImportFieldPresence.from(
        entry,
      ).hasUsableEndpointOrToken,
    );
  }
}

class _JsonConnectionImportFields {
  const _JsonConnectionImportFields({
    required this.fields,
    required this.hasExplicitConnectionFields,
  });

  final Map<dynamic, dynamic> fields;

  // Entries may inherit top-level credentials, but metadata-only entries should
  // not outrank entries that carry their own endpoint/token provenance.
  final bool hasExplicitConnectionFields;
}

Map<dynamic, dynamic> _entryFieldsWithJsonDefaults(
  Map<dynamic, dynamic> defaults,
  Map<dynamic, dynamic> entry,
) {
  final fields = Map<dynamic, dynamic>.of(defaults)..remove('entries');
  _removeDefaultJsonAliasesOverriddenByEntry(fields, entry);
  for (final entryField in entry.entries) {
    if (_isBlankJsonValue(entryField.value)) continue;
    if (_isJsonConnectionImportFieldName('${entryField.key}') &&
        !_isUsableJsonConnectionImportFieldValue(
          entryField.key,
          entryField.value,
        )) {
      continue;
    }
    fields[entryField.key] = entryField.value;
  }
  return fields;
}

void _removeDefaultJsonAliasesOverriddenByEntry(
  Map<dynamic, dynamic> fields,
  Map<dynamic, dynamic> entry,
) {
  final overridePolicy = _JsonEntryDefaultOverridePolicy.fromEntry(entry);
  for (final aliasGroup in _jsonConnectionImportFieldAliasGroups.map(
    _JsonConnectionImportAliasGroup.new,
  )) {
    if (!overridePolicy.shouldRemoveDefaultsFor(aliasGroup)) continue;
    aliasGroup.removeAliasesFrom(fields);
  }
}

class _JsonEntryDefaultOverridePolicy {
  const _JsonEntryDefaultOverridePolicy({
    required this.entry,
    required this.presence,
  });

  factory _JsonEntryDefaultOverridePolicy.fromEntry(
    Map<dynamic, dynamic> entry,
  ) {
    return _JsonEntryDefaultOverridePolicy(
      entry: entry,
      presence: _JsonConnectionImportFieldPresence.from(entry),
    );
  }

  final Map<dynamic, dynamic> entry;
  final _JsonConnectionImportFieldPresence presence;

  bool shouldRemoveDefaultsFor(_JsonConnectionImportAliasGroup aliasGroup) {
    if (aliasGroup.hasNonBlankOverrideIn(entry)) return true;
    if (!presence.hasUsableEndpointOrToken) return false;

    // Blank or non-string entry aliases are only treated as intentional
    // blockers when the entry also carries a concrete endpoint/token field.
    // This keeps metadata-only entries from erasing inherited connection
    // defaults, while still preventing explicit-but-unusable aliases from
    // manufacturing complete imports with stale defaults.
    return aliasGroup.hasUnusableOverrideIn(entry);
  }
}

class _JsonConnectionImportFieldPresence {
  const _JsonConnectionImportFieldPresence({
    required this.hasToken,
    required this.hasBaseUrl,
    required this.hasWebSocketUrl,
  });

  factory _JsonConnectionImportFieldPresence.from(
    Map<dynamic, dynamic> fields,
  ) {
    return _JsonConnectionImportFieldPresence(
      hasToken:
          navivoxFirstStringFieldFromJson(fields, _tokenFieldNames) != null,
      hasBaseUrl:
          navivoxFirstStringFieldFromJson(fields, _baseUrlFieldNames) != null,
      hasWebSocketUrl:
          navivoxFirstStringFieldFromJson(fields, _webSocketUrlFieldNames) !=
          null,
    );
  }

  final bool hasToken;
  final bool hasBaseUrl;
  final bool hasWebSocketUrl;

  bool get hasUsableEndpointOrToken =>
      hasToken || hasBaseUrl || hasWebSocketUrl;
}

class _JsonConnectionImportAliasGroup {
  _JsonConnectionImportAliasGroup(Iterable<String> aliases)
    : aliases = List.unmodifiable(aliases),
      _normalizedAliases = Set.unmodifiable(
        aliases.map(_normalizeJsonConnectionImportFieldName),
      ) {
    assert(this.aliases.isNotEmpty);
    assert(_normalizedAliases.isNotEmpty);
  }

  final List<String> aliases;
  final Set<String> _normalizedAliases;

  bool matchesKey(Object? key) {
    return _normalizedAliases.contains(
      _normalizeJsonConnectionImportFieldName('$key'),
    );
  }

  bool hasNonBlankOverrideIn(Map<dynamic, dynamic> entry) {
    return entry.entries.any(
      (entry) =>
          matchesKey(entry.key) &&
          _isUsableJsonConnectionImportFieldValue(entry.key, entry.value),
    );
  }

  bool hasUnusableOverrideIn(Map<dynamic, dynamic> entry) {
    return entry.entries.any(
      (entry) =>
          matchesKey(entry.key) &&
          !_isUsableJsonConnectionImportFieldValue(entry.key, entry.value),
    );
  }

  void removeAliasesFrom(Map<dynamic, dynamic> fields) {
    final keysToRemove = fields.keys.where(matchesKey).toList(growable: false);
    for (final key in keysToRemove) {
      fields.remove(key);
    }
  }
}

bool _isJsonConnectionImportFieldName(String name) {
  return _jsonConnectionImportFieldAliasGroups
      .map(_JsonConnectionImportAliasGroup.new)
      .any((aliases) => aliases.matchesKey(name));
}

String _normalizeJsonConnectionImportFieldName(String value) =>
    value.toLowerCase().replaceAll('_', '');

bool _isBlankJsonValue(Object? value) {
  if (value == null) return true;
  if (value is String && value.trim().isEmpty) return true;
  return false;
}

bool _isUsableJsonConnectionImportFieldValue(Object? key, Object? value) {
  if (_JsonConnectionImportAliasGroup(
    _setupSectionsFieldNames,
  ).matchesKey(key)) {
    return navivoxStringListFromJson(value).isNotEmpty ||
        _isNonBlankJsonString(value);
  }
  return _isNonBlankJsonString(value);
}

bool _isNonBlankJsonString(Object? value) =>
    value is String && value.trim().isNotEmpty;
