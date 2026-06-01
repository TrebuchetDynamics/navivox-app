part of '../parser.dart';

SetupQrImageImport? _importFromSharedText(String text) {
  final scan = _SharedTextConnectionImportScan.fromText(text);
  final coreImport = _bestCorePairingDescriptorImport(
    scan.coreDescriptorCandidates,
  );
  if (coreImport != null) return coreImport;

  final embeddedUrlCandidate = _bestGenericUrlCandidateFromSharedText(
    text,
    scan.genericEndpoints,
  );
  if (embeddedUrlCandidate == null && scan.hasEndpointLikeImportBlocker) {
    return null;
  }
  final tokenSourceText = _sharedTextWithoutMalformedCoreDescriptors(
    text,
    scan.coreDescriptorCandidates,
  );
  final token = _sharedTextImportToken(
    text: tokenSourceText,
    embeddedUrlCandidate: embeddedUrlCandidate,
  );
  if (embeddedUrlCandidate == null && token == null) return null;

  return SetupQrImageImport(
    baseUrl: embeddedUrlCandidate?.candidate.baseUrl,
    token: token,
    webSocketUrl: embeddedUrlCandidate?.candidate.webSocketUrl,
    serverId: embeddedUrlCandidate?.candidate.serverId,
    profileId: embeddedUrlCandidate?.candidate.profileId,
  );
}

class _SharedTextConnectionImportScan {
  const _SharedTextConnectionImportScan({
    required this.coreDescriptorCandidates,
    required this.genericEndpoints,
    required this.hasUnsupportedConnectionEndpoint,
  });

  factory _SharedTextConnectionImportScan.fromText(String text) {
    final coreDescriptorCandidates =
        _corePairingDescriptorCandidatesFromSharedText(
          text,
        ).toList(growable: false);
    final genericEndpoints = _endpointUrls(text).toList(growable: false);
    return _SharedTextConnectionImportScan(
      coreDescriptorCandidates: coreDescriptorCandidates,
      genericEndpoints: genericEndpoints,
      hasUnsupportedConnectionEndpoint: _hasUnsupportedConnectionEndpointUrl(
        text,
      ),
    );
  }

  final List<_SharedTextCoreDescriptorCandidate> coreDescriptorCandidates;
  final List<_SharedTextEndpoint> genericEndpoints;
  final bool hasUnsupportedConnectionEndpoint;

  bool get hasEndpointLikeImportBlocker =>
      coreDescriptorCandidates.isNotEmpty ||
      genericEndpoints.isNotEmpty ||
      hasUnsupportedConnectionEndpoint;
}

String? _sharedTextImportToken({
  required String text,
  required _SharedTextEndpointCandidate? embeddedUrlCandidate,
}) {
  final candidateToken = embeddedUrlCandidate?.candidate.token;
  if (candidateToken != null) return candidateToken;

  return _SharedTextTokenProvenance.fromSelectedEndpoint(
    embeddedUrlCandidate,
  ).firstToken(text);
}

_SharedTextEndpointCandidate? _bestGenericUrlCandidateFromSharedText(
  String text,
  Iterable<_SharedTextEndpoint> endpoints,
) {
  return _selectPreferredConnectionImportCandidate(
    endpoints
        .map((endpoint) => _sharedTextEndpointCandidate(text, endpoint))
        .whereType<_SharedTextEndpointCandidate>(),
    isPreferred: _isPreferredSharedTextEndpointCandidate,
  );
}

_SharedTextEndpointCandidate? _sharedTextEndpointCandidate(
  String text,
  _SharedTextEndpoint endpoint,
) {
  final uri = Uri.tryParse(endpoint.url);
  final candidate = uri != null && uri.hasScheme
      ? _connectionImportCandidateFromGenericUri(uri)
      : _connectionImportCandidateFromFields({'base_url': endpoint.url});
  if (candidate == null) return null;

  final followingToken = endpoint.followingToken(text);
  return _SharedTextEndpointCandidate(
    candidate: candidate,
    tokenSearchWindow: _SharedTextEndpointTokenSearchWindow.fromEndpoint(
      endpoint,
    ),
    hasFollowingToken: followingToken != null,
    hasConnectionPath: uri != null && _hasConnectionPath(uri),
  );
}
