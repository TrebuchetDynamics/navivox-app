import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/widgets/transcript_bubble.dart';

const _support = NavivoxProfileContact(
  serverId: 'office',
  profileId: 'support',
  displayName: 'Support Triage',
  serverLabel: 'office',
  health: NavivoxProfileHealth.online,
  latestPreview: 'Watching tickets',
);

void main() {
  testWidgets('renders message text and opens assistant pause action', (
    tester,
  ) async {
    var paused = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'assistant-1',
              text: 'pause this answer',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: true,
            onCancelActiveTurn: () => paused = true,
          ),
        ),
      ),
    );

    expect(find.text('pause this answer'), findsOneWidget);
    expect(find.text('11:15'), findsOneWidget);

    await tester.longPress(find.text('pause this answer'));
    await tester.pumpAndSettle();

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.text('Pause stream'), findsOneWidget);

    await tester.tap(find.text('Pause stream'));
    await tester.pumpAndSettle();

    expect(paused, isTrue);
  });

  testWidgets('renders Telegram-style sent tick for user messages', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptBubble(
              message: _textMessage(
                id: 'user-sent-1',
                text: 'sent text',
                author: NavivoxMessageAuthor.user,
              ),
              isUser: true,
              showTail: true,
            ),
          ),
        ),
      );

      expect(find.text('sent text'), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
      expect(find.bySemanticsLabel('Sent'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('does not show pause action for user messages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'user-1',
              text: 'user text',
              author: NavivoxMessageAuthor.user,
            ),
            isUser: true,
            showTail: true,
            onCancelActiveTurn: () {},
          ),
        ),
      ),
    );

    await tester.longPress(find.text('user text'));
    await tester.pumpAndSettle();

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.text('Pause stream'), findsNothing);
  });

  testWidgets('renders forward target and invokes selected Profile contact', (
    tester,
  ) async {
    NavivoxProfileContact? forwardedTo;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptBubble(
            message: _textMessage(
              id: 'forward-1',
              text: 'forward this update',
              author: NavivoxMessageAuthor.assistant,
            ),
            isUser: false,
            showTail: false,
            forwardTargets: const [_support],
            onForward: (_, target) => forwardedTo = target,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('forward this update'));
    await tester.pumpAndSettle();

    expect(find.text('Forward to'), findsOneWidget);
    expect(find.text('Support Triage'), findsOneWidget);

    await tester.tap(find.text('Support Triage'));
    await tester.pumpAndSettle();

    expect(forwardedTo, _support);
  });
}

NavivoxChatMessage _textMessage({
  required String id,
  required String text,
  required NavivoxMessageAuthor author,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime.utc(2026, 5, 23, 11, 15),
    text: text,
  );
}
