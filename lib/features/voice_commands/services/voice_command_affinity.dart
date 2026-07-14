import '../models/voice_command.dart';

/// Lexical anchor pre-router. `VoiceCommandRouter` calls [trusts] after
/// `VoiceCommandValidator.validate` returns a non-null result: a transcript
/// that contains no anchor for the proposed command is doubted and the
/// router falls through to Hermes (see
/// docs/superpowers/specs/2026-07-14-affinity-preroute-design.md). Engine
/// confidence is pinned at 1.0 and unusable, so lexical anchor evidence is
/// the don't-know signal instead.
abstract final class VoiceCommandAffinity {
  /// Anchor table calibrated against the 20-case spike bank — all 16
  /// correct matches keep at least one anchor; all 3 wrong-tool matches lose
  /// all anchors. Keep this table verbatim in sync with the spec's table;
  /// if it must change, mirror the edit into the spec doc in the same
  /// commit.
  static const Map<VoiceCommandId, List<String>> _anchors = {
    VoiceCommandId.navigateToScreen: [
      'open',
      'go to',
      'take me',
      'settings',
      'screen',
      'chat',
    ],
    VoiceCommandId.showStatus: ['status', 'connected', 'connection', 'online'],
    VoiceCommandId.stopVoiceRun: ['stop', 'cancel', 'pause', 'mute', 'quiet'],
    VoiceCommandId.startVoiceRun: ['listen', 'begin', 'start', 'voice', 'mic'],
    VoiceCommandId.toggleContinuousMode: [
      'continuous',
      'hands free',
      'hands-free',
      'handsfree',
    ],
    VoiceCommandId.newSession: ['new', 'fresh', 'conversation', 'session'],
    VoiceCommandId.switchSession: ['session', 'switch'],
    VoiceCommandId.setTtsVoice: ['voice'],
    VoiceCommandId.setSpeechRate: [
      'speed',
      'rate',
      'faster',
      'slower',
      'slow',
      'quickly',
    ],
  };

  /// True when [transcript] contains at least one lexical anchor for
  /// [command]. Both transcript and anchors are tokenized with a
  /// punctuation-robust normalization (lowercase, every non-alphanumeric
  /// run becomes a token boundary): single-token anchors match by token
  /// membership, multi-token anchors by contiguous token-subsequence match.
  /// Substring matches across token boundaries never count ("lets go
  /// together" does not match "go to") and punctuation never defeats an
  /// anchor ("please stop." matches "stop"; "hands-free" tokenizes the
  /// same as "hands free").
  static bool trusts(String transcript, VoiceCommandId command) {
    final tokens = _tokenize(transcript);
    for (final anchor in _anchors[command] ?? const <String>[]) {
      if (_containsTokenSequence(tokens, _tokenize(anchor))) return true;
    }
    return false;
  }

  static List<String> _tokenize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList();

  static bool _containsTokenSequence(List<String> tokens, List<String> seq) {
    if (seq.isEmpty) return false;
    if (seq.length == 1) return tokens.contains(seq.single);
    for (var i = 0; i + seq.length <= tokens.length; i++) {
      var match = true;
      for (var j = 0; j < seq.length; j++) {
        if (tokens[i + j] != seq[j]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }
}
