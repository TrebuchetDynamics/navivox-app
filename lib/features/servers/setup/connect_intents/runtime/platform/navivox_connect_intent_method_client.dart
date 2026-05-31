import 'package:flutter/services.dart';

import 'navivox_connect_intent_channels.dart';

class NavivoxConnectIntentMethodClient {
  const NavivoxConnectIntentMethodClient(this._methodChannel);

  final MethodChannel _methodChannel;

  Future<NavivoxInitialConnectIntentRead> readInitialPayload() async {
    try {
      final payload = await _methodChannel.invokeMethod<Object?>(
        initialNavivoxConnectIntentMethod,
      );
      return NavivoxInitialConnectIntentRead.available(payload);
    } on MissingPluginException {
      return const NavivoxInitialConnectIntentRead.unavailable();
    } on PlatformException {
      return const NavivoxInitialConnectIntentRead.unavailable();
    }
  }
}

class NavivoxInitialConnectIntentRead {
  const NavivoxInitialConnectIntentRead._({
    required this.isAvailable,
    required this.payload,
  });

  const NavivoxInitialConnectIntentRead.available(Object? payload)
    : this._(isAvailable: true, payload: payload);

  const NavivoxInitialConnectIntentRead.unavailable()
    : this._(isAvailable: false, payload: null);

  final bool isAvailable;
  final Object? payload;
}
