part of '../../parser.dart';

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
