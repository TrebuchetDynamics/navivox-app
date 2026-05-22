import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/widgets/simple_chat_adapter.dart';

void main() {
  testWidgets('disabled STT mic explains recovery in simple chat adapter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimpleChatAdapter(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            voiceUnavailableReason: 'device STT unavailable',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(
      find.byTooltip('Voice unavailable: device STT unavailable'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expect(find.text('Voice unavailable'), findsOneWidget);
    expect(find.text('device STT unavailable'), findsOneWidget);
    expect(
      find.text(
        'Install or enable device speech recognition, then reopen Navivox.',
      ),
      findsOneWidget,
    );
  });
}
