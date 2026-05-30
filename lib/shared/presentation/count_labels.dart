String countLabel(int count, String singular, {String? plural}) {
  final noun = count == 1 ? singular : plural ?? '${singular}s';
  return '$count $noun';
}
