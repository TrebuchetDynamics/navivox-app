import '../../../core/hermes/models/hermes_chat_turn.dart';

/// Decides which assistant reply (if any) hands-free continuous voice should
/// speak aloud now.
///
/// Pure: callers own TTS playback, last-spoken tracking, and re-arming
/// capture. `turns` is expected to already be scoped to the active session
/// (e.g. `HermesChannelState.activeMessages`). Returns the newest completed
/// assistant turn that has not been spoken yet, or null when auto-speak
/// should not fire.
HermesChatTurn? hermesContinuousVoiceReplyToSpeak({
  required List<HermesChatTurn> turns,
  required bool enabled,
  required String? lastSpokenTurnId,
}) {
  if (!enabled) return null;

  HermesChatTurn? latest;
  for (final turn in turns) {
    if (turn.author != HermesTurnAuthor.assistant) continue;
    if (turn.status != HermesTurnStatus.completed) continue;
    if (turn.text.trim().isEmpty) continue;
    latest = turn;
  }

  if (latest == null || latest.id == lastSpokenTurnId) return null;
  return latest;
}
