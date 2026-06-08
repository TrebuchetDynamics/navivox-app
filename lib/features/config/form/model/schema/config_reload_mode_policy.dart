/// Pure reload-mode policy for schema rows.
///
/// A reload mode requires restart when it contains a `restart` token that is
/// not explicitly negated by an immediately preceding `no` or `without` token.
bool configFormReloadModeRequiresRestart(String reloadMode) {
  final tokens = configFormReloadModeTokens(reloadMode);
  for (var index = 0; index < tokens.length; index += 1) {
    if (tokens[index] != 'restart') continue;
    if (_isNegatedRestart(tokens, index)) continue;
    return true;
  }
  return false;
}

List<String> configFormReloadModeTokens(String reloadMode) {
  return reloadMode
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

bool _isNegatedRestart(List<String> tokens, int restartIndex) {
  if (restartIndex == 0) return false;
  return switch (tokens[restartIndex - 1]) {
    'no' || 'without' => true,
    _ => false,
  };
}
