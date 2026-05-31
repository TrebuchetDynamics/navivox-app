String transcriptJoinInfoParts(Iterable<String> parts) {
  return parts.join(' • ');
}

String? transcriptJoinOptionalInfoParts(Iterable<String> parts) {
  final partList = parts.toList(growable: false);
  return partList.isEmpty ? null : transcriptJoinInfoParts(partList);
}
