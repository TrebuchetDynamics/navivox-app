import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';

/// Mounts a widget under the minimal Material scaffold used by feature widget tests.
class TestMaterialScaffold extends StatelessWidget {
  const TestMaterialScaffold({required this.body, super.key});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: body));
  }
}

/// Mounts a feature screen in the standard Navivox test shell.
///
/// Use this for screen tests that only need a mocked [NavivoxChannel] plus
/// Material scaffolding, and do not need the app router.
class TestNavivoxMaterialApp extends StatelessWidget {
  const TestNavivoxMaterialApp({
    required this.channel,
    required this.home,
    super.key,
  });

  final NavivoxChannel channel;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [navivoxChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(home: home),
    );
  }
}
