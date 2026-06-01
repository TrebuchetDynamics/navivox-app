part of '../../../parser.dart';

class _SharedTextEndpointCandidate {
  const _SharedTextEndpointCandidate({
    required this.candidate,
    required this.tokenSearchWindow,
    required this.hasFollowingToken,
    required this.hasConnectionPath,
  });

  final _ConnectionImportCandidate candidate;
  final _SharedTextEndpointTokenSearchWindow tokenSearchWindow;
  final bool hasFollowingToken;
  final bool hasConnectionPath;

  _SharedTextTokenProvenance get tokenProvenance =>
      tokenSearchWindow.provenance;

  bool isRicherThan(_SharedTextEndpointCandidate? other) {
    return _isPreferredSharedTextEndpointCandidate(this, other);
  }
}

bool _isPreferredSharedTextEndpointCandidate(
  _SharedTextEndpointCandidate candidate,
  _SharedTextEndpointCandidate? currentBest,
) {
  if (currentBest == null) return true;
  return _SharedTextEndpointSelectionSignals.fromCandidate(
    candidate,
  ).isPreferredOver(
    _SharedTextEndpointSelectionSignals.fromCandidate(currentBest),
  );
}

class _SharedTextEndpointSelectionSignals {
  const _SharedTextEndpointSelectionSignals({
    required this.rank,
    required this.hasCompleteConnection,
    required this.hasFollowingToken,
    required this.hasConnectionPath,
  });

  factory _SharedTextEndpointSelectionSignals.fromCandidate(
    _SharedTextEndpointCandidate candidate,
  ) {
    return _SharedTextEndpointSelectionSignals(
      rank: candidate.candidate.rank,
      hasCompleteConnection: candidate.candidate.hasCompleteConnection,
      hasFollowingToken: candidate.hasFollowingToken,
      hasConnectionPath: candidate.hasConnectionPath,
    );
  }

  final _ConnectionImportCandidateRank rank;
  final bool hasCompleteConnection;
  final bool hasFollowingToken;
  final bool hasConnectionPath;

  bool isPreferredOver(_SharedTextEndpointSelectionSignals other) {
    final decision = _SharedTextEndpointSelectionDecisionFactory.between(
      candidate: this,
      incumbent: other,
    );
    return decision == _SharedTextEndpointSelectionDecision.candidate;
  }

  bool get hasExactlyOneActionableSignal =>
      hasCompleteConnection != hasConnectionPath;

  bool get hasExactlyOneTokenProvenanceSignal =>
      hasCompleteConnection != hasFollowingToken;
}

enum _SharedTextEndpointSelectionDecision { candidate, incumbent, tie }

abstract final class _SharedTextEndpointSelectionDecisionFactory {
  static _SharedTextEndpointSelectionDecision between({
    required _SharedTextEndpointSelectionSignals candidate,
    required _SharedTextEndpointSelectionSignals incumbent,
  }) {
    // Shared text commonly reads as "docs/example first, then actual handoff".
    // When the incumbent and candidate each expose exactly one strong but
    // different signal (embedded credential vs. route path, or embedded
    // credential vs. following-token provenance on non-route URLs), keep the
    // later URL window. This avoids letting an earlier docs query token hide a
    // later handoff while still allowing a later credentialed endpoint to beat
    // an earlier route-only docs URL.
    final laterComplementarySignalDecision = _preferLaterComplementarySignal(
      candidate,
      incumbent,
    );
    if (laterComplementarySignalDecision !=
        _SharedTextEndpointSelectionDecision.tie) {
      return laterComplementarySignalDecision;
    }

    // A URL carrying both endpoint and token is already an actionable handoff.
    // Do not let a nearby bare documentation/setup URL steal selection merely
    // because its path happens to contain connection-route vocabulary.
    final completeConnectionDecision = _preferTrue(
      candidate.hasCompleteConnection,
      incumbent.hasCompleteConnection,
    );
    if (completeConnectionDecision !=
        _SharedTextEndpointSelectionDecision.tie) {
      return completeConnectionDecision;
    }

    // Shared text often contains documentation URLs before the actual pairing
    // handoff URL. Prefer explicit connection-route vocabulary before generic
    // richness so a stale docs query token cannot outrank the real endpoint.
    final connectionPathDecision = _preferTrue(
      candidate.hasConnectionPath,
      incumbent.hasConnectionPath,
    );
    if (connectionPathDecision != _SharedTextEndpointSelectionDecision.tie) {
      return connectionPathDecision;
    }

    // When two URLs expose the same completeness/connection-route signals,
    // bind prose tokens to the URL whose following segment actually contains
    // the token.
    final followingTokenDecision = _preferTrue(
      candidate.hasFollowingToken,
      incumbent.hasFollowingToken,
    );
    if (followingTokenDecision != _SharedTextEndpointSelectionDecision.tie) {
      return followingTokenDecision;
    }

    return _preferRicherRank(candidate.rank, incumbent.rank);
  }

  static _SharedTextEndpointSelectionDecision _preferLaterComplementarySignal(
    _SharedTextEndpointSelectionSignals candidate,
    _SharedTextEndpointSelectionSignals incumbent,
  ) {
    if (_hasComplementaryActionableSignals(candidate, incumbent)) {
      return _SharedTextEndpointSelectionDecision.candidate;
    }
    if (_hasComplementaryTokenProvenanceSignals(candidate, incumbent)) {
      return _SharedTextEndpointSelectionDecision.candidate;
    }
    return _SharedTextEndpointSelectionDecision.tie;
  }

  static bool _hasComplementaryActionableSignals(
    _SharedTextEndpointSelectionSignals candidate,
    _SharedTextEndpointSelectionSignals incumbent,
  ) {
    return candidate.hasExactlyOneActionableSignal &&
        incumbent.hasExactlyOneActionableSignal &&
        candidate.hasCompleteConnection != incumbent.hasCompleteConnection;
  }

  static bool _hasComplementaryTokenProvenanceSignals(
    _SharedTextEndpointSelectionSignals candidate,
    _SharedTextEndpointSelectionSignals incumbent,
  ) {
    if (candidate.hasConnectionPath || incumbent.hasConnectionPath) {
      return false;
    }
    return candidate.hasExactlyOneTokenProvenanceSignal &&
        incumbent.hasExactlyOneTokenProvenanceSignal &&
        candidate.hasCompleteConnection != incumbent.hasCompleteConnection;
  }

  static _SharedTextEndpointSelectionDecision _preferTrue(
    bool candidate,
    bool incumbent,
  ) {
    if (candidate == incumbent) return _SharedTextEndpointSelectionDecision.tie;
    return candidate
        ? _SharedTextEndpointSelectionDecision.candidate
        : _SharedTextEndpointSelectionDecision.incumbent;
  }

  static _SharedTextEndpointSelectionDecision _preferRicherRank(
    _ConnectionImportCandidateRank candidate,
    _ConnectionImportCandidateRank incumbent,
  ) {
    if (candidate.isRicherThan(incumbent)) {
      return _SharedTextEndpointSelectionDecision.candidate;
    }
    if (incumbent.isRicherThan(candidate)) {
      return _SharedTextEndpointSelectionDecision.incumbent;
    }
    return _SharedTextEndpointSelectionDecision.tie;
  }
}

class _SharedTextTokenProvenance {
  const _SharedTextTokenProvenance({
    required this.hasSelectedEndpoint,
    required this.followingSearchStart,
    required this.followingSearchEnd,
    required this.leadingSearchEnd,
  }) : assert(followingSearchStart >= 0),
       assert(followingSearchEnd >= followingSearchStart),
       assert(leadingSearchEnd >= 0);

  const _SharedTextTokenProvenance.withoutSelectedEndpoint()
    : hasSelectedEndpoint = false,
      followingSearchStart = 0,
      followingSearchEnd = 0,
      leadingSearchEnd = 0;

  factory _SharedTextTokenProvenance.fromSelectedEndpoint(
    _SharedTextEndpointCandidate? selectedEndpoint,
  ) {
    return selectedEndpoint?.tokenProvenance ??
        const _SharedTextTokenProvenance.withoutSelectedEndpoint();
  }

  final bool hasSelectedEndpoint;
  final int followingSearchStart;
  final int followingSearchEnd;
  final int leadingSearchEnd;

  String? firstToken(String text) {
    if (!hasSelectedEndpoint) return _firstToken(text);

    // Keep token provenance aligned with the selected URL candidate. Tokens
    // after the selected URL are more likely to describe that endpoint than
    // stale prose tokens copied earlier in the share text. Preserve older
    // token-before-URL imports without borrowing tokens from later URL windows.
    return _firstToken(
          text,
          start: followingSearchStart,
          end: followingSearchEnd,
        ) ??
        _lastToken(text, end: leadingSearchEnd);
  }
}
