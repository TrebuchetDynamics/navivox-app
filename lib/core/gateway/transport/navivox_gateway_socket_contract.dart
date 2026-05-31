import 'dart:async';

/// Shared socket contract implemented by all Navivox gateway transports.
///
/// Platform transports keep their concrete socket wrappers for compatibility,
/// while this interface names the common stream/send/close behavior they expose.
abstract interface class NavivoxGatewaySocketConnection {
  Stream<dynamic> get events;

  void add(String message);

  Future<void> close();
}
