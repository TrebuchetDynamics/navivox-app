part of 'parser.dart';

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

  bool get hasImportValues => baseUrl != null || token != null;

  bool get hasCompleteConnection => baseUrl != null && token != null;

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

class _ConnectionImportCandidateRank {
  const _ConnectionImportCandidateRank({
    required this.isCompleteConnection,
    required this.hasExplicitConnectionFields,
    required this.fieldCoverage,
  });

  final bool isCompleteConnection;
  final bool hasExplicitConnectionFields;
  final _ConnectionImportFieldCoverage fieldCoverage;

  bool isRicherThan(_ConnectionImportCandidateRank other) {
    if (isCompleteConnection != other.isCompleteConnection) {
      return isCompleteConnection;
    }
    if (hasExplicitConnectionFields != other.hasExplicitConnectionFields) {
      return hasExplicitConnectionFields;
    }
    return fieldCoverage.score > other.fieldCoverage.score;
  }
}

class _ConnectionImportFieldCoverage {
  const _ConnectionImportFieldCoverage({
    required this.hasBaseUrl,
    required this.hasToken,
    required this.hasWebSocketUrl,
    required this.hasServerId,
    required this.hasProfileId,
  });

  static const _connectionFieldWeight = 2;
  static const _metadataFieldWeight = 1;

  final bool hasBaseUrl;
  final bool hasToken;
  final bool hasWebSocketUrl;
  final bool hasServerId;
  final bool hasProfileId;

  int get score {
    var result = 0;
    if (hasBaseUrl) result += _connectionFieldWeight;
    if (hasToken) result += _connectionFieldWeight;
    if (hasWebSocketUrl) result += _metadataFieldWeight;
    if (hasServerId) result += _metadataFieldWeight;
    if (hasProfileId) result += _metadataFieldWeight;
    return result;
  }
}

_ConnectionImportCandidate _richerConnectionImportCandidate({
  required _ConnectionImportCandidate? currentBest,
  required _ConnectionImportCandidate candidate,
}) {
  // A complete baseUrl+token candidate can still be lower-fidelity than a later
  // complete candidate carrying provenance metadata. Selection therefore scores
  // all candidates instead of short-circuiting at the first complete import.
  return candidate.isRicherThan(currentBest) ? candidate : currentBest!;
}
