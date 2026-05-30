/// Shared presentation policy for local voice-capture unavailable states.
///
/// Keep these labels centralized because the chat composer and readiness UI both
/// surface the same Android speech-recognition blockers through different rows.
String? canonicalVoiceUnavailableReason(
  String? reason, {
  bool emptyAsNull = false,
}) {
  final trimmed = reason?.trim();
  if (trimmed == null) return null;
  if (trimmed.isEmpty) return emptyAsNull ? null : trimmed;
  final normalized = trimmed.toLowerCase();
  if (normalized == 'device stt unavailable') return 'device STT unavailable';
  if (normalized == 'microphone permission denied') {
    return 'microphone permission denied';
  }
  return trimmed;
}

String? defaultVoiceUnavailableRecoveryAction(String reason) {
  if (reason == 'device STT unavailable') {
    return 'Install or enable device speech recognition, then return to Navivox.';
  }
  if (reason == 'microphone permission denied') {
    return 'Grant microphone permission in Android App info, then return to Navivox.';
  }
  return null;
}

String voiceUnavailableHelpText(String? reason) {
  return defaultVoiceUnavailableRecoveryAction(reason ?? '') ??
      (reason == 'select a profile contact'
          ? 'Select a profile contact before using continuous voice.'
          : 'Check microphone permissions and Settings.');
}

String voiceSettingsSubtitleForUnavailableReason(String? reason) {
  return reason == 'device STT unavailable'
      ? 'Review continuous voice after enabling device speech recognition.'
      : reason == 'microphone permission denied'
      ? 'Review continuous voice after granting microphone permission.'
      : reason == 'select a profile contact'
      ? 'Select a profile contact before reviewing continuous voice settings.'
      : 'Review continuous voice and trust settings';
}
