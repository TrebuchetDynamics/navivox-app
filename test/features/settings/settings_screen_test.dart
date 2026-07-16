import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel_state.dart';
import 'package:navivox/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

void main() {
  testWidgets('copies the bounded Hermes diagnostics snapshot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connected,
      models: const ['hermes-3'],
    );
    addTearDown(channel.dispose);
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            const EmptyHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final copy = find.byKey(const ValueKey('settings-copy-diagnostics'));
    await tester.scrollUntilVisible(copy, 300);
    await tester.tap(copy);
    await tester.pump();

    expect(copiedText, contains('Navivox Hermes diagnostics'));
    expect(copiedText, contains('Models: hermes-3'));
    expect(copiedText, contains('Secrets: excluded'));
    expect(find.text('Hermes diagnostics copied'), findsOneWidget);
  });
}
