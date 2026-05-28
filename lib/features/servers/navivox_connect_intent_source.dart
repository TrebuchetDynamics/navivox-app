import 'dart:async';

import 'package:flutter/services.dart';

import 'setup_qr_import_presentation.dart';

class NavivoxConnectIntentSource {
  const NavivoxConnectIntentSource({
    MethodChannel methodChannel = const MethodChannel(_methodChannelName),
    EventChannel eventChannel = const EventChannel(_eventChannelName),
  }) : _methodChannel = methodChannel,
       _eventChannel = eventChannel;

  static const _methodChannelName =
      'com.trebuchetdynamics.navivox/connect_intents';
  static const _eventChannelName =
      'com.trebuchetdynamics.navivox/connect_intents/events';

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Future<bool> isAvailable() async {
    try {
      await _methodChannel.invokeMethod<Object?>('initialConnectIntent');
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<SetupQrImageImport?> initialImport() async {
    final payload = await _initialPayload();
    if (payload == null) return null;
    return _parseConnectIntentPayload(payload);
  }

  Stream<SetupQrImageImport> get imports {
    return _eventChannel
        .receiveBroadcastStream()
        .handleError((_) {})
        .map(_parseConnectIntentPayload)
        .where((result) => result != null && result.hasValues)
        .cast<SetupQrImageImport>();
  }

  Future<Object?> _initialPayload() async {
    try {
      return await _methodChannel.invokeMethod<Object?>('initialConnectIntent');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

SetupQrImageImport? _parseConnectIntentPayload(Object? payload) {
  if (payload is String) {
    final text = payload.trim();
    if (text.isEmpty) return null;
    return parseNavivoxQrPayload(text);
  }
  if (payload is! Map) return null;
  final text = payload['payload']?.toString().trim();
  if (text == null || text.isEmpty) return null;
  final parsed = parseNavivoxQrPayload(text);
  if (parsed == null) return null;
  return parsed.withSource(_sourceFromPayload(payload['source']));
}

PairingHandoffSource _sourceFromPayload(Object? value) {
  return switch (value?.toString()) {
    'direct_app_open' => PairingHandoffSource.directAppOpen,
    'shared_text' => PairingHandoffSource.sharedText,
    _ => PairingHandoffSource.manual,
  };
}
