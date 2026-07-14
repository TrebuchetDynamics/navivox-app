enum VoiceCommandId {
  navigateToScreen('navigate_to_screen'),
  showStatus('show_status'),
  stopVoiceRun('stop_voice_run'),
  toggleContinuousMode('toggle_continuous_mode'),
  startVoiceRun('start_voice_run'),
  newSession('new_session'),
  switchSession('switch_session'),
  setTtsVoice('set_tts_voice'),
  setSpeechRate('set_speech_rate');

  const VoiceCommandId(this.wireName);

  final String wireName;
}

enum VoiceCommandTier { instant, confirm }

/// A validated, snapped, ready-to-dispatch local command. Carrying the
/// original transcript lets decline paths deliver it to Hermes unchanged.
class VoiceRouteResult {
  const VoiceRouteResult({
    required this.command,
    required this.args,
    required this.tier,
    required this.transcript,
  });

  final VoiceCommandId command;
  final Map<String, Object?> args;
  final VoiceCommandTier tier;
  final String transcript;

  String describe() {
    switch (command) {
      case VoiceCommandId.navigateToScreen:
        final screen = args['screen'] == 'settings' ? 'Settings' : 'Hermes';
        return 'Opening $screen';
      case VoiceCommandId.showStatus:
        return 'Showing connection status';
      case VoiceCommandId.stopVoiceRun:
        return 'Stopping voice capture';
      case VoiceCommandId.toggleContinuousMode:
        return args['enabled'] == true
            ? 'Turn on continuous voice?'
            : 'Turning off continuous voice';
      case VoiceCommandId.startVoiceRun:
        return 'Start listening?';
      case VoiceCommandId.newSession:
        return 'Start a new session?';
      case VoiceCommandId.switchSession:
        return 'Switch to session "${args['session_name']}"?';
      case VoiceCommandId.setTtsVoice:
        return 'Use voice "${args['voice']}"?';
      case VoiceCommandId.setSpeechRate:
        return 'Set speech rate to ${args['rate']}?';
    }
  }
}
