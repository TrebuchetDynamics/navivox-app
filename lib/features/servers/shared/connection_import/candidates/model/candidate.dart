part of '../../parser.dart';

class _ConnectionImportCandidate {
  const _ConnectionImportCandidate({
    this.baseUrl,
    this.token,
    this.webSocketUrl,
    this.serverId,
    this.profileId,
    this.hasExplicitConnectionFields = true,
  }) : assert(baseUrl == null || baseUrl.length > 0),
       assert(token == null || token.length > 0),
       assert(webSocketUrl == null || webSocketUrl.length > 0),
       assert(serverId == null || serverId.length > 0),
       assert(profileId == null || profileId.length > 0);

  final String? baseUrl;
  final String? token;
  final String? webSocketUrl;
  final String? serverId;
  final String? profileId;
  final bool hasExplicitConnectionFields;

  _ConnectionImportValuePresence get _valuePresence =>
      _ConnectionImportValuePresence(baseUrl: baseUrl, token: token);

  bool get hasImportValues => _valuePresence.hasActionableImport;

  bool get hasCompleteConnection => _valuePresence.hasCompleteConnection;

  _ConnectionImportCandidateRank get rank => _ConnectionImportCandidateRank(
    isCompleteConnection: hasCompleteConnection,
    hasExplicitConnectionFields: hasExplicitConnectionFields,
    fieldCoverage: _fieldCoverage,
  );

  _ConnectionImportFieldCoverage get _fieldCoverage =>
      _ConnectionImportFieldCoverage(
        hasBaseUrl: baseUrl != null,
        hasToken: token != null,
        hasWebSocketUrl: webSocketUrl != null,
        hasServerId: serverId != null,
        hasProfileId: profileId != null,
      );

  bool isRicherThan(_ConnectionImportCandidate? other) {
    return other == null || rank.isRicherThan(other.rank);
  }

  SetupQrImageImport toImport() {
    return SetupQrImageImport(
      baseUrl: baseUrl,
      token: token,
      webSocketUrl: webSocketUrl,
      serverId: serverId,
      profileId: profileId,
    );
  }
}

bool _isPreferredConnectionImportCandidate(
  _ConnectionImportCandidate candidate,
  _ConnectionImportCandidate? currentBest,
) {
  // A complete baseUrl+token candidate can still be lower-fidelity than a later
  // complete candidate carrying provenance metadata. Selection therefore scores
  // all candidates instead of short-circuiting at the first complete import.
  return candidate.isRicherThan(currentBest);
}
