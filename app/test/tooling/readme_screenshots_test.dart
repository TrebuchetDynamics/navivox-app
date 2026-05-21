import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';

import '../support/test_navivox_channel.dart';

const _screenSize = Size(390, 844);
const _screenshotKey = ValueKey('readme-screenshot');

void main() {
  testWidgets(
    'README setup screenshot is rendered from the real setup screen',
    (tester) async {
      await _setScreenSize(tester);

      await tester.pumpWidget(
        _ScreenshotFrame(
          channel: TestNavivoxChannel(),
          child: const SetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(_screenshotKey),
        matchesGoldenFile('../../../docs/screenshots/setup.png'),
      );
    },
  );

  testWidgets('README chat screenshot is rendered from the real chat screen', (
    tester,
  ) async {
    await _setScreenSize(tester);
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready to work',
          micAvailable: true,
          activeTurnState: 'streaming',
        ),
      ], selectedKey: 'local::mineru')
      ..seedMessages([
        NavivoxChatMessage(
          id: 'user-1',
          author: NavivoxMessageAuthor.user,
          kind: NavivoxMessageKind.text,
          createdAt: DateTime.utc(2026, 5, 21, 12),
          text: 'Summarize the workspace status.',
        ),
        NavivoxChatMessage(
          id: 'assistant-1',
          author: NavivoxMessageAuthor.assistant,
          kind: NavivoxMessageKind.text,
          createdAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
          text: 'Navivox is connected and the gateway stream is healthy.',
        ),
        NavivoxChatMessage(
          id: 'tool-1',
          author: NavivoxMessageAuthor.assistant,
          kind: NavivoxMessageKind.toolCall,
          createdAt: DateTime.utc(2026, 5, 21, 12, 0, 2),
          toolCall: const NavivoxToolCall(
            name: 'status',
            status: 'finished',
            summary: '2 roots checked, 0 blockers.',
          ),
        ),
      ]);

    await tester.pumpWidget(
      _ScreenshotFrame(
        channel: channel,
        child: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await expectLater(
      find.byKey(_screenshotKey),
      matchesGoldenFile('../../../docs/screenshots/chat.png'),
    );
  });
}

Future<void> _setScreenSize(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = _screenSize;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _ScreenshotFrame extends StatelessWidget {
  const _ScreenshotFrame({required this.channel, required this.child});

  final TestNavivoxChannel channel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [navivoxChannelProvider.overrideWithValue(channel)],
      child: RepaintBoundary(
        key: _screenshotKey,
        child: MaterialApp(
          title: 'Navivox',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff256d85),
            ),
            useMaterial3: true,
          ),
          home: child,
        ),
      ),
    );
  }
}
