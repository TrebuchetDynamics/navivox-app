/// SharedPreferences keys used for non-secret session persistence metadata.
class SessionPreferenceKeys {
  const SessionPreferenceKeys._();

  static const baseUrl = 'navivox.session.base_url';
  static const webSocketUrl = 'navivox.session.websocket_url';
  static const legacyToken = 'navivox.session.token';
  static const lastConnectedAt = 'navivox.session.last_connected_at';
  static const gatewayId = 'navivox.session.gateway_id';
}
