// E2E test entry point for Playwright testing.
// Uses a mock channel pre-seeded with gateway, profiles, and messages
// so Playwright tests can navigate all app screens without a real gateway.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/channel/navivox_channel_provider.dart';
import 'router/app_router.dart';
import 'testing/e2e_mock_channel.dart';
import 'theme/navivox_theme.dart';

void main() {
  final channel = E2EMockChannel();
  channel.connect(baseUrl: 'http://127.0.0.1:8765', token: 'nvbx_e2e_token');

  runApp(
    ProviderScope(
      overrides: [navivoxChannelProvider.overrideWithValue(channel)],
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
