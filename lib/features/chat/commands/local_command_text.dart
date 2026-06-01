/// Text-shaping helpers shared by local command parsing and profile matching.
///
/// Local command matching intentionally uses a small ASCII command alphabet:
/// command words, built-ins, server IDs, and profile IDs are matched after
/// lowercasing and collapsing non-`a-z0-9` runs to a single space.
String normalizeLocalCommandText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool isLocalCommandWordSeparator(int codeUnit) {
  return codeUnit == 0x20 || // space
      codeUnit == 0x09 || // tab
      codeUnit == 0x0a || // line feed
      codeUnit == 0x0d || // carriage return
      codeUnit == 0x2c || // comma
      codeUnit == 0x2e || // period
      codeUnit == 0x3a || // colon
      codeUnit == 0x3b || // semicolon
      codeUnit == 0x21 || // exclamation mark
      codeUnit == 0x3f; // question mark
}
