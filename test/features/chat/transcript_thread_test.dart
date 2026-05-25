import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/widgets/transcript_thread.dart';

const _support = NavivoxProfileContact(
  serverId: 'office',
  profileId: 'support',
  displayName: 'Support Triage',
  serverLabel: 'office',
  health: NavivoxProfileHealth.online,
  latestPreview: 'Watching tickets',
);

void main() {
  testWidgets('renders the shared empty Transcript surface state', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _ThreadHost(
        scrollController: scrollController,
        messages: const <NavivoxChatMessage>[],
      ),
    );

    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.text('Start a conversation'), findsOneWidget);
  });

  testWidgets('adds Telegram-style date chips at calendar boundaries', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _ThreadHost(
        scrollController: scrollController,
        messages: [
          _textMessage(
            id: 'day-one-a',
            text: 'First day',
            author: NavivoxMessageAuthor.assistant,
            createdAt: DateTime.utc(2026, 5, 22, 9),
          ),
          _textMessage(
            id: 'day-one-b',
            text: 'Same day',
            author: NavivoxMessageAuthor.user,
            createdAt: DateTime.utc(2026, 5, 22, 10),
          ),
          _textMessage(
            id: 'day-two',
            text: 'Next day',
            author: NavivoxMessageAuthor.assistant,
            createdAt: DateTime.utc(2026, 5, 23, 8),
          ),
        ],
      ),
    );

    expect(find.text('May 22'), findsOneWidget);
    expect(find.text('May 23'), findsOneWidget);
  });

  testWidgets('renders typing indicator and exposes pause for active stream', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    var paused = false;

    await tester.pumpWidget(
      _ThreadHost(
        scrollController: scrollController,
        messages: [
          _textMessage(
            id: 'assistant-1',
            text: 'Drafting the deployment plan.',
            author: NavivoxMessageAuthor.assistant,
          ),
        ],
        assistantTypingLabel: 'Mineru is typing…',
        onCancelActiveTurn: () => paused = true,
      ),
    );

    expect(find.text('Mineru is typing…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assistant-typing-indicator')),
      findsOneWidget,
    );

    await tester.longPress(find.text('Drafting the deployment plan.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pause stream'), findsOneWidget);

    await tester.tap(find.text('Pause stream'));
    await tester.pump();

    expect(paused, isTrue);
  });

  testWidgets('keeps forward targets wired from the shared thread', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    NavivoxProfileContact? forwardedTo;

    await tester.pumpWidget(
      _ThreadHost(
        scrollController: scrollController,
        messages: [
          _textMessage(
            id: 'assistant-1',
            text: 'Forward this note',
            author: NavivoxMessageAuthor.assistant,
          ),
        ],
        forwardTargets: const [_support],
        onForward: (_, target) => forwardedTo = target,
      ),
    );

    await tester.longPress(find.text('Forward this note'));
    await tester.pumpAndSettle();

    expect(find.text('Forward to'), findsOneWidget);
    expect(find.text('Support Triage'), findsOneWidget);

    await tester.tap(find.text('Support Triage'));
    await tester.pumpAndSettle();

    expect(forwardedTo, _support);
  });
}

class _ThreadHost extends StatelessWidget {
  const _ThreadHost({
    required this.scrollController,
    required this.messages,
    this.assistantTypingLabel,
    this.forwardTargets = const [],
    this.onForward,
    this.onCancelActiveTurn,
  });

  final ScrollController scrollController;
  final List<NavivoxChatMessage> messages;
  final String? assistantTypingLabel;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;
  final VoidCallback? onCancelActiveTurn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: TranscriptThread(
          messages: messages,
          scrollController: scrollController,
          assistantTypingLabel: assistantTypingLabel,
          forwardTargets: forwardTargets,
          onForward: onForward,
          onCancelActiveTurn: onCancelActiveTurn,
        ),
      ),
    );
  }
}

NavivoxChatMessage _textMessage({
  required String id,
  required String text,
  required NavivoxMessageAuthor author,
  DateTime? createdAt,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.text,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 23, 11, 15),
    text: text,
  );
}
