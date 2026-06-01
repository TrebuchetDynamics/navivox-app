part of '../parser.dart';

SetupQrImageImport? _importFromSharedText(String text) {
  final coreDescriptorCandidates =
      _corePairingDescriptorCandidatesFromSharedText(
        text,
      ).toList(growable: false);
  final coreImport = _bestCorePairingDescriptorImport(coreDescriptorCandidates);
  if (coreImport != null) return coreImport;

  final genericEndpoints = _endpointUrls(text).toList(growable: false);
  final embeddedUrlCandidate = _bestGenericUrlCandidateFromSharedText(
    text,
    genericEndpoints,
  );
  if (embeddedUrlCandidate == null &&
      (coreDescriptorCandidates.isNotEmpty || genericEndpoints.isNotEmpty)) {
    return null;
  }
  final tokenSourceText = _sharedTextWithoutMalformedCoreDescriptors(
    text,
    coreDescriptorCandidates,
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
  _SharedTextEndpointCandidate? bestCandidate;
  for (final endpoint in endpoints) {
    final candidate = _sharedTextEndpointCandidate(text, endpoint);
    if (candidate == null) continue;
    bestCandidate = candidate.isRicherThan(bestCandidate)
        ? candidate
        : bestCandidate;
  }
  return bestCandidate;
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
    tokenSearchStart: endpoint.tokenWindow.start,
    tokenSearchEnd: endpoint.tokenWindow.end,
    leadingTokenSearchEnd: endpoint.sourceWindow.start,
    hasFollowingToken: followingToken != null,
    canUseLeadingToken: !endpoint.hasPriorEndpoint,
    hasConnectionPath: uri != null && _hasConnectionPath(uri),
  );
}
