// E2E test entry point for Playwright testing.
// Uses a mock channel pre-seeded with gateway, profiles, and messages
// so Playwright tests can navigate all app screens without a real gateway.

import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/channel/navivox_channel_provider.dart';
import 'core/hermes/channel/hermes_api_channel.dart';
import 'features/hermes_chat/providers/hermes_channel_provider.dart';
import 'router/app_router.dart';
import 'testing/e2e_mock_channel.dart';
import 'theme/navivox_theme.dart';

@JS('navivoxE2ESendText')
external set _navivoxE2ESendText(JSFunction callback);

@JS('navivoxE2ESetConfigAdmin')
external set _navivoxE2ESetConfigAdmin(JSFunction callback);

@JS('navivoxE2EHermesConnect')
external set _navivoxE2EHermesConnect(JSFunction callback);

@JS('navivoxE2EHermesSendText')
external set _navivoxE2EHermesSendText(JSFunction callback);

@JS('navivoxE2EHermesSubmitVoice')
external set _navivoxE2EHermesSubmitVoice(JSFunction callback);

void main() {
  final channel = E2EMockChannel();
  final hermesChannel = HermesApiChannel();
  channel.connect(baseUrl: 'http://127.0.0.1:8765', token: 'nvbx_e2e_token');
  _navivoxE2ESendText = ((JSString text) {
    channel.sendText(text.toDart);
  }).toJS;
  _navivoxE2ESetConfigAdmin = ((JSString mode) {
    switch (mode.toDart) {
      case 'available':
        channel.setConfigAdminMode(E2EConfigAdminMode.available);
      case 'load_failed':
        channel.setConfigAdminMode(E2EConfigAdminMode.loadFailed);
      default:
        channel.setConfigAdminMode(E2EConfigAdminMode.unsupported);
    }
  }).toJS;
  _navivoxE2EHermesConnect = (() {
    hermesChannel.connect(baseUrl: 'http://127.0.0.1:8767');
  }).toJS;
  _navivoxE2EHermesSendText = ((JSString text) {
    hermesChannel.sendText(text.toDart);
  }).toJS;
  _navivoxE2EHermesSubmitVoice = ((JSString text) {
    final id = hermesChannel.startVoiceRun();
    hermesChannel.stageVoiceRunTranscript(
      voiceRunId: id,
      transcript: text.toDart,
      duration: const Duration(seconds: 2),
      confidence: 0.95,
    );
    hermesChannel.submitVoiceRun(id);
  }).toJS;

  runApp(
    ProviderScope(
      overrides: [
        navivoxChannelProvider.overrideWithValue(channel),
        hermesChannelProvider.overrideWithValue(hermesChannel),
      ],
      child: const _E2ETestApp(),
    ),
  );
}

class _E2ETestApp extends ConsumerWidget {
  const _E2ETestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Navivox',
      theme: navivoxLightTheme,
      darkTheme: navivoxDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
