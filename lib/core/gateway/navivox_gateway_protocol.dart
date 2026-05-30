library;

/// Public barrel for the Navivox gateway protocol layer.
///
/// Re-exports all gateway protocol types, messages, capabilities, voice,
/// config-admin, and observation types from their responsibility-focused
/// subpackages.
export '../protocol/navivox_pairing_descriptor.dart';
export 'navivox_gateway_config.dart';

export 'capabilities/navivox_gateway_capabilities.dart';
export 'config_admin/navivox_gateway_config_admin.dart';
export 'messages/navivox_gateway_event.dart';
export 'messages/navivox_gateway_message.dart';
export 'observations/navivox_gateway_observations.dart';
export 'shared/navivox_gateway_constants.dart';
export 'voice/navivox_gateway_voice.dart';
