/// Reconnect-safe projection for a saved websocket endpoint.
///
/// Saved session metadata may keep the websocket path because deployments can
/// mount the stream outside the default Navivox route. It must not keep
/// userinfo, query parameters, or fragments because those fields can contain
/// one-time pairing credentials.
class SavedSessionWebSocketEndpoint {
  const SavedSessionWebSocketEndpoint._(this.uri);

  static SavedSessionWebSocketEndpoint? tryParse(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'ws' && scheme != 'wss') return null;
    return SavedSessionWebSocketEndpoint._(
      Uri(
        scheme: scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path,
      ),
    );
  }

  final Uri uri;

  String get durableUrl => uri.toString();
}
