class NavivoxInitialConnectIntentPayloadCache {
  Object? _payload;
  bool _hasPayload = false;

  bool get hasPayload => _hasPayload;

  void remember(Object? payload) {
    _payload = payload;
    _hasPayload = true;
  }

  Object? take() {
    final payload = _payload;
    _payload = null;
    _hasPayload = false;
    return payload;
  }
}
