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
  _ConnectionImportCandidate? bestCandidate;
  for (final candidate in candidates) {
    bestCandidate = _richerConnectionImportCandidate(
      currentBest: bestCandidate,
      candidate: candidate,
    );
  }
  return bestCandidate;
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
    hasExplicitConnectionFields: hasExplicitConnectionFields,
  );
  if (!candidate.hasImportValues) return null;

  return candidate;
}
