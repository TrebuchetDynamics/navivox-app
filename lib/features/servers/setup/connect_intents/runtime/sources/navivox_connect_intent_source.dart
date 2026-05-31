import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../models/connection_import.dart';
import '../../payloads/navivox_connect_intent_initial_payload.dart';
import '../../payloads/navivox_connect_intent_payload.dart';
import '../contracts/navivox_connect_intent_observer.dart';
import '../platform/navivox_connect_intent_channels.dart';
import '../platform/navivox_connect_intent_method_client.dart';

class NavivoxConnectIntentSource {
  NavivoxConnectIntentSource({
    MethodChannel methodChannel = const MethodChannel(
      navivoxConnectIntentMethodChannelName,
    ),
    EventChannel eventChannel = const EventChannel(
      navivoxConnectIntentEventChannelName,
    ),
    NavivoxConnectIntentObserver? observer,
    NavivoxInitialConnectIntentPayloadCache? initialPayloadCache,
  }) : _methodClient = NavivoxConnectIntentMethodClient(methodChannel),
       _eventChannel = eventChannel,
       _observer = observer,
       _initialPayloadCache =
           initialPayloadCache ?? NavivoxInitialConnectIntentPayloadCache();

  final NavivoxConnectIntentMethodClient _methodClient;
  final EventChannel _eventChannel;
  final NavivoxConnectIntentObserver? _observer;
  final NavivoxInitialConnectIntentPayloadCache _initialPayloadCache;

  Future<bool> isAvailable() async {
    final read = await _methodClient.readInitialPayload();
    _initialPayloadCache.remember(read.payload);
    return read.isAvailable;
  }

  Future<SetupQrImageImport?> initialImport() async {
    final payload = await _initialPayload();
    if (payload == null) return null;
    final result = parseNavivoxConnectIntentPayload(payload);
    if (result != null) _observer?.record(result);
    return result;
  }

  Stream<SetupQrImageImport> get imports {
    return _eventChannel
        .receiveBroadcastStream()
        .handleError((_) {})
        .map(parseNavivoxConnectIntentPayload)
        .where((result) => result != null && result.hasValues)
        .cast<SetupQrImageImport>()
        .map((result) {
          _observer?.record(result);
          return result;
        });
  }

  Future<Object?> _initialPayload() async {
    if (_initialPayloadCache.hasPayload) {
      return _initialPayloadCache.take();
    }
    final read = await _methodClient.readInitialPayload();
    return read.payload;
  }
}
