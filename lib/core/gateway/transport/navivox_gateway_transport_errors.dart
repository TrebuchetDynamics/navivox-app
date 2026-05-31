/// Shared transport error factories for unsupported gateway platform features.
///
/// Keeping these messages in one contract prevents stub transports from
/// drifting between HTTP and WebSocket entrypoints while preserving the exact
/// UnsupportedError behavior exposed by the compatibility facades.
const navivoxGatewayUnsupportedHttpMessage =
    'Navivox gateway HTTP is not supported here.';

/// Error message used when WebSocket transport is unavailable on a platform.
const navivoxGatewayUnsupportedWebSocketMessage =
    'Navivox gateway WebSocket is not supported here.';

/// Builds the platform-stub HTTP unsupported error.
UnsupportedError navivoxGatewayUnsupportedHttp() {
  return UnsupportedError(navivoxGatewayUnsupportedHttpMessage);
}

/// Builds the platform-stub WebSocket unsupported error.
UnsupportedError navivoxGatewayUnsupportedWebSocket() {
  return UnsupportedError(navivoxGatewayUnsupportedWebSocketMessage);
}
