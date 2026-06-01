/// Replayable shape classification for saved-session URI-ish metadata text.
///
/// Dart's URI parser treats host-port legacy values such as
/// `gateway.local:8765/path` as scheme-shaped. Saved-session metadata preserves
/// those compatibility values, but rejects explicit URI shapes because they can
/// carry bootstrap-only state in userinfo, query strings, or fragments.
enum SavedSessionUriTextShape {
  none,
  authorityUrl,
  namedScheme,
  hostPortLike,
  bracketedHostLiteral;

  bool get isExplicitUriScheme => switch (this) {
    SavedSessionUriTextShape.authorityUrl ||
    SavedSessionUriTextShape.namedScheme => true,
    _ => false,
  };
}

SavedSessionUriTextShape classifySavedSessionUriTextShape(String value) {
  final text = value.trim();
  if (text.isEmpty) return SavedSessionUriTextShape.none;

  // Dart's URI parser treats bracketed IPv6 host literals such as
  // `[::1]:8765/stream` as scheme-shaped because the first colon appears inside
  // the address. They are legacy host metadata, not bootstrap-token URLs.
  if (_startsWithBracketedHostLiteral(text)) {
    return SavedSessionUriTextShape.bracketedHostLiteral;
  }

  // Classify visibly URL-shaped text before consulting Uri.tryParse. Malformed
  // authority URLs such as `wss://host:bad/path` may not parse, but they are
  // still unsafe to preserve as legacy text because query/fragment/userinfo
  // could carry bootstrap credentials.
  if (_hasAuthoritySchemeSeparator(text)) {
    return SavedSessionUriTextShape.authorityUrl;
  }

  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme) return SavedSessionUriTextShape.none;

  // Dart's URI parser treats `host:8765/path` as a URI with scheme `host`.
  // Saved-session metadata also accepts legacy non-URL text, so only discard
  // values that are visibly URL/scheme-shaped rather than host-port-shaped.
  if (_hasPortLikeSchemeSeparator(text)) {
    return SavedSessionUriTextShape.hostPortLike;
  }
  return _hasNonPortSchemeSeparator(text)
      ? SavedSessionUriTextShape.namedScheme
      : SavedSessionUriTextShape.none;
}

bool _startsWithBracketedHostLiteral(String value) {
  if (!value.startsWith('[')) return false;
  final closingBracket = value.indexOf(']');
  if (closingBracket <= 1) return false;
  if (closingBracket == value.length - 1) return true;

  final nextCodeUnit = value.codeUnitAt(closingBracket + 1);
  return nextCodeUnit == 0x2f || nextCodeUnit == 0x3a; // `/` or `:`.
}

bool _hasAuthoritySchemeSeparator(String value) {
  return value.indexOf('://') > 0;
}

bool _hasPortLikeSchemeSeparator(String value) {
  final separator = value.indexOf(':');
  if (separator <= 0 || separator == value.length - 1) return false;
  return _startsWithAsciiDigit(value, separator + 1);
}

bool _hasNonPortSchemeSeparator(String value) {
  final separator = value.indexOf(':');
  if (separator <= 0 || separator == value.length - 1) return false;
  return !_startsWithAsciiDigit(value, separator + 1);
}

bool _startsWithAsciiDigit(String value, int index) {
  final codeUnit = value.codeUnitAt(index);
  return codeUnit >= 0x30 && codeUnit <= 0x39;
}
