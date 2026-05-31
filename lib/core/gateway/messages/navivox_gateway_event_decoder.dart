import 'dart:convert';

import '../shared/navivox_gateway_json.dart';
import 'navivox_gateway_event.dart';

/// Decodes one raw WebSocket event payload into the typed gateway event model.
///
/// The gateway stream can deliver already-decoded objects in tests/adapters or
/// JSON strings from real sockets. Invalid payloads are normalized to the same
/// typed error event so clients do not duplicate wire-shape checks.
NavivoxGatewayEvent navivoxGatewayEventFromWire(Object? event) {
  final decoded = event is String ? jsonDecode(event) : event;
  final object = navivoxGatewayOptionalObjectFromJson(decoded);
  if (object == null) {
    return const NavivoxGatewayEvent(
      type: 'error',
      code: 'bad_response',
      message: 'Invalid gateway event',
    );
  }
  return NavivoxGatewayEvent.fromJson(object);
}
