enum LocalCommandBuiltin { cancel, stop, settings, help }

const localCommandBuiltinWords = {
  'cancel': LocalCommandBuiltin.cancel,
  'stop': LocalCommandBuiltin.stop,
  'settings': LocalCommandBuiltin.settings,
  'help': LocalCommandBuiltin.help,
};

/// Resolves reserved local command words after the caller has normalized input.
///
/// Keeping reserved words in one pure contract makes the precedence explicit:
/// built-ins are handled before profile-name matching, so profiles named
/// "cancel", "stop", "settings", or "help" remain unreachable by bare local
/// command text unless a more specific alias is added elsewhere.
LocalCommandBuiltin? localCommandBuiltinFromNormalizedBody(String normalized) {
  return localCommandBuiltinWords[normalized.trim()];
}

String localCommandHelpMessage(String commandWord) {
  return 'Voice commands: $commandWord <profile>, cancel, stop, settings, help.';
}
