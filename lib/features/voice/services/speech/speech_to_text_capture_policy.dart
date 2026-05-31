import '../../../../core/protocol/voice_unavailable_reason.dart';

class SpeechToTextSnapshot {
  const SpeechToTextSnapshot({
    required this.words,
    required this.confidence,
    required this.finalResult,
  });

  final String words;
  final double confidence;
  final bool finalResult;
}

bool isTerminalSpeechToTextStatus(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == 'done' || normalized == 'notlistening';
}

SpeechToTextSnapshot? latestUsableSpeechToTextTranscript({
  required SpeechToTextSnapshot? current,
  required SpeechToTextSnapshot candidate,
}) {
  if (candidate.words.trim().isEmpty) return current;
  return candidate;
}

SpeechToTextSnapshot completionSpeechToTextTranscript({
  required SpeechToTextSnapshot terminalSnapshot,
  required SpeechToTextSnapshot? latestUsableSnapshot,
}) {
  if (terminalSnapshot.words.trim().isNotEmpty) return terminalSnapshot;
  return latestUsableSnapshot ?? terminalSnapshot;
}

String speechToTextDeviceUnavailableReasonFromMessage(String message) {
  final normalized = message.trim().toLowerCase();
  final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (normalized.contains('permission') ||
      normalized.contains('denied') ||
      compact.contains('notallowed')) {
    return microphonePermissionDeniedReason;
  }
  return deviceSttUnavailableReason;
}
