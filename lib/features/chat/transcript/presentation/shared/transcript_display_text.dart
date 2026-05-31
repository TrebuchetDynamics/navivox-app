bool transcriptHasDisplayText(String? value) => value?.isNotEmpty == true;

String transcriptJoinNonEmptyLines(Iterable<String?> parts) {
  return parts.whereType<String>().where(transcriptHasDisplayText).join('\n');
}
