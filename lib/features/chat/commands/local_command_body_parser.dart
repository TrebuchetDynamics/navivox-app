enum LocalCommandBodySource { prefixed, commandModeVoice }

class LocalCommandBodyParse {
  const LocalCommandBodyParse({required this.body, required this.source});

  final String body;
  final LocalCommandBodySource source;
}

class LocalCommandBodyParser {
  const LocalCommandBodyParser();

  LocalCommandBodyParse? parse(
    String raw, {
    required String commandWord,
    required bool commandMode,
    required bool fromVoice,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final word = commandWord.trim().toLowerCase();
    if (word.isEmpty) return null;

    final prefixed = _matchCommandPrefix(text, word);
    if (prefixed != null) {
      return LocalCommandBodyParse(
        body: prefixed.body,
        source: LocalCommandBodySource.prefixed,
      );
    }
    if (commandMode && fromVoice) {
      return LocalCommandBodyParse(
        body: text,
        source: LocalCommandBodySource.commandModeVoice,
      );
    }
    return null;
  }

  String? commandBody(
    String raw, {
    required String commandWord,
    required bool commandMode,
    required bool fromVoice,
  }) {
    return parse(
      raw,
      commandWord: commandWord,
      commandMode: commandMode,
      fromVoice: fromVoice,
    )?.body;
  }

  _LocalCommandPrefixMatch? _matchCommandPrefix(
    String text,
    String commandWord,
  ) {
    final lower = text.toLowerCase();
    if (lower == commandWord) {
      return const _LocalCommandPrefixMatch(body: '');
    }
    if (!lower.startsWith(commandWord)) return null;
    if (text.length == commandWord.length) {
      return const _LocalCommandPrefixMatch(body: '');
    }

    final separator = text.substring(commandWord.length);
    final bodyStart = _commandBodyStart(separator);
    if (bodyStart == null) return null;
    return _LocalCommandPrefixMatch(
      body: separator.substring(bodyStart).trim(),
    );
  }

  int? _commandBodyStart(String separatorAndBody) {
    for (var index = 0; index < separatorAndBody.length; index += 1) {
      final codeUnit = separatorAndBody.codeUnitAt(index);
      if (_isCommandWordSeparator(codeUnit)) continue;
      return index == 0 ? null : index;
    }
    return separatorAndBody.isEmpty ? null : separatorAndBody.length;
  }

  bool _isCommandWordSeparator(int codeUnit) {
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
}

class _LocalCommandPrefixMatch {
  const _LocalCommandPrefixMatch({required this.body});

  final String body;
}
