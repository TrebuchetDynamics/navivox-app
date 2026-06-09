part of '../../parser.dart';

SetupQrImageImport? _bestImportFromCandidateMaps(
  Iterable<_JsonConnectionImportFields> candidateMaps,
) {
  return _bestConnectionImportCandidate(
    _jsonConnectionImportCandidates(candidateMaps),
  )?.toImport();
}

Iterable<_ConnectionImportCandidate> _jsonConnectionImportCandidates(
  Iterable<_JsonConnectionImportFields> candidateMaps,
) sync* {
  for (final candidateFields in candidateMaps) {
    final candidate = _connectionImportCandidateFromFields(
      candidateFields.fields,
      hasExplicitConnectionFields: candidateFields.hasExplicitConnectionFields,
    );
    if (candidate != null) yield candidate;
  }
}

_ConnectionImportCandidate? _bestConnectionImportCandidate(
  Iterable<_ConnectionImportCandidate> candidates,
) {
  return _selectPreferredConnectionImportCandidate(
    candidates,
    isPreferred: _isPreferredConnectionImportCandidate,
  );
}

_ConnectionImportCandidate? _connectionImportCandidateFromFields(
  Map<dynamic, dynamic> fields, {
  String? fallbackBaseUrl,
  bool hasExplicitConnectionFields = true,
}) {
  final explicitToken = navivoxFirstStringFieldFromJson(
    fields,
    _tokenFieldNames,
  );
  final endpointFields = _connectionImportEndpointFields(fields);
  final candidate = _ConnectionImportCandidate(
    baseUrl: endpointFields.baseUrl ?? fallbackBaseUrl,
    token: explicitToken ?? endpointFields.queryToken,
    webSocketUrl: endpointFields.webSocketUrl,
    serverId: navivoxFirstStringFieldFromJson(fields, _serverIdFieldNames),
    profileId: navivoxFirstStringFieldFromJson(fields, _profileIdFieldNames),
    setupIntent: _setupIntentFromFields(fields),
    hasExplicitConnectionFields: hasExplicitConnectionFields,
  );
  if (!candidate.hasImportValues) return null;

  return candidate;
}

PairingHandoffSetupIntent _setupIntentFromFields(Map<dynamic, dynamic> fields) {
  return PairingHandoffSetupIntent(
    entryScreen: navivoxFirstStringFieldFromJson(
      fields,
      _setupEntryScreenFieldNames,
    ),
    sections: _setupSectionsFromFields(fields),
  );
}

List<String> _setupSectionsFromFields(Map<dynamic, dynamic> fields) {
  for (final name in _setupSectionsFieldNames) {
    final value = fields[name];
    final list = navivoxStringListFromJson(value);
    if (list.isNotEmpty) return list;
    final text = navivoxOptionalStringFromJson(value);
    if (text == null) continue;
    final sections = text
        .split(',')
        .map((section) => section.trim())
        .where((section) => section.isNotEmpty)
        .toList(growable: false);
    if (sections.isNotEmpty) return sections;
  }
  return const [];
}
