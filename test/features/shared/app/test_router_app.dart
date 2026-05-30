import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/router/app_router.dart';

/// A [ConsumerWidget] that mounts the app router for integration tests.
///
/// Intended for use inside a [ProviderScope] with any channel overrides:
/// ```dart
/// ProviderScope(
///   overrides: [navivoxChannelProvider.overrideWithValue(channel)],
///   child: const TestRouterApp(),
/// )
/// ```
class TestRouterApp extends ConsumerWidget {
  const TestRouterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}

/// Mounts the app router with a mocked [NavivoxChannel] override.
class TestNavivoxRouterApp extends StatelessWidget {
  const TestNavivoxRouterApp({required this.channel, super.key});

  final NavivoxChannel channel;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [navivoxChannelProvider.overrideWithValue(channel)],
      child: const TestRouterApp(),
    );
  }
}
