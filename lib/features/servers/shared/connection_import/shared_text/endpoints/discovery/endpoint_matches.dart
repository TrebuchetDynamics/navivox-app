part of '../../../parser.dart';

Iterable<_SharedTextEndpoint> _endpointUrls(String text) =>
    _sharedTextEndpoints(text);

bool _hasUnsupportedConnectionEndpointUrl(String text) {
  for (final match in _uriLikeUrlPattern.allMatches(text)) {
    final matchedText = match.group(0);
    if (matchedText == null) continue;
    final endpointText = _endpointUrlCandidateText(matchedText);
    if (endpointText == null) continue;
    final uri = Uri.tryParse(endpointText.url);
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
    final endpointText = _endpointUrlCandidateText(matchedText);
    if (endpointText == null) continue;

    yield _SharedTextEndpointMatch(
      url: endpointText.url,
      sourceWindow: _TextWindow(start: match.start, end: match.end),
      trailingPunctuationWindow: _TextWindow(
        start: match.start + endpointText.end,
        end: match.end,
      ),
    );
  }
}

_EndpointUrlCandidateText? _endpointUrlCandidateText(String matchedText) {
  final start = _copiedEndpointUrlStart(matchedText);
  final rawEnd = _endpointUrlEndBeforeAttachedTokenLabel(
    matchedText,
    start: start,
  );
  final end = _copiedEndpointUrlEnd(
    matchedText.substring(0, rawEnd),
    start: start,
  );
  if (end <= start) return null;
  return _EndpointUrlCandidateText(
    start: start,
    end: end,
    url: matchedText.substring(start, end),
  );
}

class _EndpointUrlCandidateText {
  const _EndpointUrlCandidateText({
    required this.start,
    required this.end,
    required this.url,
  }) : assert(start >= 0),
       assert(end >= start),
       assert(url.length > 0);

  final int start;
  final int end;
  final String url;
}

int _endpointUrlEndBeforeAttachedTokenLabel(
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

bool _hasAttachedTokenLabelAfterCopiedEndpoint(String copiedUrl) {
  return _endpointUrlEndBeforeAttachedTokenLabel(copiedUrl, start: 0) <
      copiedUrl.length;
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
