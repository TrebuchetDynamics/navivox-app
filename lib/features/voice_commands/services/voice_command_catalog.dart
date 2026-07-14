import 'dart:convert';

import '../models/voice_command.dart';

/// Real command surface offered to Needle. `send_message` is intentionally
/// absent: unmatched transcripts fall through to Hermes, which IS the send
/// path — modeling it as a tool would only invite wrong-tool swallowing.
abstract final class VoiceCommandCatalog {
  static Map<String, dynamic> _tool(
    String name,
    String description,
    Map<String, dynamic> properties,
    List<String> required,
  ) {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': properties,
          'required': required,
        },
      },
    };
  }

  static final List<Map<String, dynamic>> tools = [
    _tool(
      'navigate_to_screen',
      'Open one of the app screens.',
      {
        'screen': {
          'type': 'string',
          'enum': ['hermes', 'settings'],
          'description': 'Which screen to open.',
        },
      },
      ['screen'],
    ),
    _tool('show_status', 'Show the agent connection status.', {}, []),
    _tool(
      'stop_voice_run',
      'Stop listening / stop the current voice capture.',
      {},
      [],
    ),
    _tool(
      'toggle_continuous_mode',
      'Turn hands-free continuous voice mode on or off.',
      {
        'enabled': {
          'type': 'boolean',
          'description': 'true to enable continuous mode.',
        },
      },
      ['enabled'],
    ),
    _tool(
      'start_voice_run',
      'Start listening for the next voice command.',
      {},
      [],
    ),
    _tool('new_session', 'Start a fresh chat session.', {}, []),
    _tool(
      'switch_session',
      'Switch to a named chat session.',
      {
        'session_name': {
          'type': 'string',
          'description': 'Name of the session to switch to.',
        },
      },
      ['session_name'],
    ),
    _tool(
      'set_tts_voice',
      'Change the text-to-speech voice.',
      {
        'voice': {'type': 'string', 'description': 'Voice name to use.'},
      },
      ['voice'],
    ),
    _tool(
      'set_speech_rate',
      'Change how fast replies are read aloud.',
      {
        'rate': {
          'type': 'number',
          'description': 'Speech rate multiplier; 1.0 is normal.',
        },
      },
      ['rate'],
    ),
  ];

  static final String toolsJson = jsonEncode(tools);

  static final Map<String, VoiceCommandId> _byWire = {
    for (final id in VoiceCommandId.values) id.wireName: id,
  };

  static VoiceCommandId? byWireName(String name) => _byWire[name];
}
