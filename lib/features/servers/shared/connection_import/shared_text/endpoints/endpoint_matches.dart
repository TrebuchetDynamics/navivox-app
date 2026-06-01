part of '../../parser.dart';

Iterable<_SharedTextEndpoint> _endpointUrls(String text) =>
    _sharedTextEndpoints(text);

bool _hasUnsupportedConnectionEndpointUrl(String text) {
  for (final match in _uriLikeUrlPattern.allMatches(text)) {
    final matchedText = match.group(0);
    if (matchedText == null) continue;
    final url = _trimCopiedEndpointUrl(matchedText);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) continue;
    if (!_hasConnectionPath(uri)) continue;
    if (_isCorePairingDescriptorUri(uri)) continue;
    if (_ConnectionImportEndpointUriIdentity.fromUri(uri).isSupported) continue;
    return true;
  }
  return false;
}

Iterable<_SharedTextEndpointMatch> _endpointUrlMatches(String text) sync* {
  for (final match in _endpointUrlPattern.allMatches(text)) {
    final matchedText = match.group(0);
    if (matchedText == null) continue;
    final trimmedUrlStart = _copiedEndpointUrlStart(matchedText);
    final rawUrlEnd = _matchedEndpointUrlEndBeforeAttachedTokenLabel(
      matchedText,
      start: trimmedUrlStart,
    );
    final trimmedUrlEnd = _copiedEndpointUrlEnd(
      matchedText.substring(0, rawUrlEnd),
      start: trimmedUrlStart,
    );
    if (trimmedUrlEnd <= trimmedUrlStart) continue;

    yield _SharedTextEndpointMatch(
      url: matchedText.substring(trimmedUrlStart, trimmedUrlEnd),
      sourceWindow: _TextWindow(start: match.start, end: match.end),
      trailingPunctuationWindow: _TextWindow(
        start: match.start + trimmedUrlEnd,
        end: match.end,
      ),
    );
  }
}

int _matchedEndpointUrlEndBeforeAttachedTokenLabel(
  String matchedText, {
  required int start,
}) {
  final boundaryPattern = _attachedTokenLabelBoundaryPattern();
  int? earliestTokenLabelStart;
  for (final label in _tokenLabels) {
    final labelPattern = RegExp(
      '$boundaryPattern\\s*${RegExp.escape(label)}\\s*[:=]',
      caseSensitive: false,
    );
    final match = labelPattern.firstMatch(matchedText.substring(start));
    if (match == null) continue;
    final labelStart = start + match.start;
    if (earliestTokenLabelStart == null ||
        labelStart < earliestTokenLabelStart) {
      earliestTokenLabelStart = labelStart;
    }
  }
  return earliestTokenLabelStart ?? matchedText.length;
}

bool _hasConnectionPath(Uri uri) {
  return uri.pathSegments.any(
    (segment) => _connectionPathSegments.contains(segment.toLowerCase()),
  );
}

const _connectionPathSegments = {'connect', 'connection', 'pair', 'pairing'};

final _uriLikeUrlPattern = RegExp(
  r'\b[a-z][a-z0-9+.-]*://\S+',
  caseSensitive: false,
);

String _attachedTokenLabelBoundaryPattern() {
  final punctuationAlternation = _attachedTokenLabelPunctuation
      .map(RegExp.escape)
      .join('|');
  return '(?:$punctuationAlternation)';
}
