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

/// Reasons saved-session metadata text must not be preserved verbatim.
///
/// These are replayable evidence for the reconnect-safety decision: explicit
/// URI schemes may hide authority/userinfo semantics, while legacy-shaped text
/// can still carry one-time pairing state in URI subfields.
enum SavedSessionUriTextUnsafeReason {
  explicitUriScheme,
  query,
  fragment,
  userInfo,
}

/// Legacy-shaped metadata delimiters that can hide one-time pairing state.
enum SavedSessionUriTextUnsafeDelimiter { query, fragment, userInfo }

SavedSessionUriTextShape classifySavedSessionUriTextShape(String value) {
  return SavedSessionUriTextFacts.fromText(value).shape;
}

/// Replayable URI-ish text facts that drive saved-session persistence safety.
///
/// This value type keeps shape classification and secret-bearing delimiter
/// checks on the same normalized text, so base-url and websocket metadata cannot
/// drift on whether legacy text is safe to preserve.
class SavedSessionUriTextFacts {
  const SavedSessionUriTextFacts._({required this.syntax, required this.shape});

  factory SavedSessionUriTextFacts.fromText(String value) {
    final syntax = SavedSessionUriTextSyntax.parse(value);
    return SavedSessionUriTextFacts._(
      syntax: syntax,
      shape: _classifySavedSessionUriTextSyntax(syntax),
    );
  }

  final SavedSessionUriTextSyntax syntax;
  final SavedSessionUriTextShape shape;

  /// Replayable reasons the raw text must not be kept as compatibility text.
  List<SavedSessionUriTextUnsafeReason> get unsafeLegacyPreservationReasons {
    return [
      if (shape.isExplicitUriScheme)
        SavedSessionUriTextUnsafeReason.explicitUriScheme,
      for (final delimiter in syntax.unsafeLegacyDelimiters)
        _unsafeReasonFromDelimiter(delimiter),
    ];
  }

  /// True when the raw text is visibly URI-shaped or carries URI subfields that
  /// can hold one-time pairing credentials and must not be kept as legacy text.
  bool get isUnsafeToPreserveAsLegacy {
    return unsafeLegacyPreservationReasons.isNotEmpty;
  }
}

SavedSessionUriTextUnsafeReason _unsafeReasonFromDelimiter(
  SavedSessionUriTextUnsafeDelimiter delimiter,
) {
  return switch (delimiter) {
    SavedSessionUriTextUnsafeDelimiter.query =>
      SavedSessionUriTextUnsafeReason.query,
    SavedSessionUriTextUnsafeDelimiter.fragment =>
      SavedSessionUriTextUnsafeReason.fragment,
    SavedSessionUriTextUnsafeDelimiter.userInfo =>
      SavedSessionUriTextUnsafeReason.userInfo,
  };
}

SavedSessionUriTextShape _classifySavedSessionUriTextSyntax(
  SavedSessionUriTextSyntax syntax,
) {
  if (syntax.isBlank) return SavedSessionUriTextShape.none;

  // Dart's URI parser treats bracketed IPv6 host literals such as
  // `[::1]:8765/stream` as scheme-shaped because the first colon appears inside
  // the address. They are legacy host metadata, not bootstrap-token URLs.
  if (syntax.startsWithBracketedHostLiteral) {
    return SavedSessionUriTextShape.bracketedHostLiteral;
  }

  // Classify visibly URL-shaped text before consulting Uri.tryParse. Malformed
  // authority URLs such as `wss://host:bad/path` may not parse, but they are
  // still unsafe to preserve as legacy text because query/fragment/userinfo
  // could carry bootstrap credentials.
  if (syntax.hasAuthoritySchemeSeparator) {
    return SavedSessionUriTextShape.authorityUrl;
  }

  final uri = Uri.tryParse(syntax.text);
  if (uri == null || !uri.hasScheme) return SavedSessionUriTextShape.none;

  // Dart's URI parser treats `host:8765/path` as a URI with scheme `host`.
  // Saved-session metadata also accepts legacy non-URL text, so only discard
  // values that are visibly URL/scheme-shaped rather than host-port-shaped.
  if (syntax.hasPortLikeSchemeSeparator) {
    return SavedSessionUriTextShape.hostPortLike;
  }
  return syntax.hasNonPortSchemeSeparator
      ? SavedSessionUriTextShape.namedScheme
      : SavedSessionUriTextShape.none;
}

/// Replayable syntax facts used by saved-session URI text classification.
///
/// These facts intentionally avoid deciding whether text is safe to persist.
/// They only expose the separators that drive the classifier so tests can pin
/// Dart URI parser quirks separately from reconnect-safety policy.
class SavedSessionUriTextSyntax {
  const SavedSessionUriTextSyntax._({
    required this.text,
    required int firstColonIndex,
  }) : _firstColonIndex = firstColonIndex;

  factory SavedSessionUriTextSyntax.parse(String value) {
    final text = value.trim();
    return SavedSessionUriTextSyntax._(
      text: text,
      firstColonIndex: text.indexOf(':'),
    );
  }

  final String text;
  final int _firstColonIndex;

  bool get isBlank => text.isEmpty;

  bool get startsWithBracketedHostLiteral {
    if (!text.startsWith('[')) return false;
    final closingBracket = text.indexOf(']');
    if (closingBracket <= 1) return false;
    if (closingBracket == text.length - 1) return true;

    final nextIndex = closingBracket + 1;
    final nextCodeUnit = text.codeUnitAt(nextIndex);
    if (nextCodeUnit == _slash) return true;
    if (nextCodeUnit != _colon) return false;

    // `[::1]:8765/stream` is legacy bracketed-host text. `[::1]://...` is
    // visibly authority-URL-shaped and can carry query/fragment credentials.
    return !_startsWithAuthoritySeparator(text, nextIndex);
  }

  bool get hasAuthoritySchemeSeparator => text.indexOf('://') > 0;

  bool get hasPortLikeSchemeSeparator {
    if (_firstColonIndex <= 0 || _firstColonIndex == text.length - 1) {
      return false;
    }
    return _startsWithAsciiDigit(text, _firstColonIndex + 1);
  }

  bool get hasNonPortSchemeSeparator {
    if (_firstColonIndex <= 0 || _firstColonIndex == text.length - 1) {
      return false;
    }
    return !_startsWithAsciiDigit(text, _firstColonIndex + 1);
  }

  /// URI subfield delimiters found in otherwise legacy-shaped metadata.
  ///
  /// Keeping the exact delimiter reasons replayable prevents the base-url and
  /// websocket projections from drifting on whether `?`, `#`, or `@` should
  /// reject preservation of old host-port text.
  List<SavedSessionUriTextUnsafeDelimiter> get unsafeLegacyDelimiters {
    return [
      if (text.contains('?')) SavedSessionUriTextUnsafeDelimiter.query,
      if (text.contains('#')) SavedSessionUriTextUnsafeDelimiter.fragment,
      if (text.contains('@')) SavedSessionUriTextUnsafeDelimiter.userInfo,
    ];
  }

  /// True when legacy-shaped metadata still contains URI subfields that can
  /// carry one-time pairing state and should not be preserved verbatim.
  bool get hasNonDurableUriStateDelimiter => unsafeLegacyDelimiters.isNotEmpty;
}

const int _colon = 0x3a;
const int _slash = 0x2f;

bool _startsWithAsciiDigit(String value, int index) {
  final codeUnit = value.codeUnitAt(index);
  return codeUnit >= 0x30 && codeUnit <= 0x39;
}

bool _startsWithAuthoritySeparator(String value, int index) {
  return value.startsWith('://', index);
}
