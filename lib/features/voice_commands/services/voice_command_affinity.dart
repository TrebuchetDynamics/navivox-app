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
  /// [command]. Normalization matches `VoiceCommandValidator`: trim,
  /// lowercase, collapse whitespace. Multiword anchors are matched by phrase
  /// containment; single-word anchors by word-boundary containment.
  static bool trusts(String transcript, VoiceCommandId command) {
    final normalized = _normalize(transcript);
    final anchors = _anchors[command] ?? const [];
    final words = normalized.split(' ');
    for (final anchor in anchors) {
      if (anchor.contains(' ')) {
        if (normalized.contains(anchor)) return true;
      } else {
        if (words.contains(anchor)) return true;
      }
    }
    return false;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
