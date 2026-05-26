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
      await _methodChannel.invokeMethod<String>('initialConnectIntent');
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
    return parseNavivoxQrPayload(payload);
  }

  Stream<SetupQrImageImport> get imports {
    return _eventChannel
        .receiveBroadcastStream()
        .handleError((_) {})
        .where((event) => event is String)
        .cast<String>()
        .map(parseNavivoxQrPayload)
        .where((result) => result != null && result.hasValues)
        .cast<SetupQrImageImport>();
  }

  Future<String?> _initialPayload() async {
    try {
      final payload = await _methodChannel.invokeMethod<String>(
        'initialConnectIntent',
      );
      final text = payload?.trim();
      return text == null || text.isEmpty ? null : text;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
