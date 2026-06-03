import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/actions/transcript_message_action_coordinator.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_message_action_presentation.dart';

void main() {
  const coordinator = TranscriptMessageActionCoordinator();
  final message = NavivoxChatMessage(
    id: 'assistant-1',
    author: NavivoxMessageAuthor.assistant,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime.utc(2026, 1, 1),
    text: 'hello',
    runRecordReference: 'run-1',
  );
  final presentation = TranscriptMessageActionPresentation.fromMessage(
    message,
    textToSpeechAvailable: true,
    canCancelActiveTurn: true,
    runRecordInspectionAvailable: true,
  );

  test('copy action carries text and snackbar copy', () {
    final effect = coordinator.copyText(presentation);

    expect(effect, isA<CopyTextMessageActionEffect>());
    expect((effect as CopyTextMessageActionEffect).text, 'hello');
    expect(effect.snackbarMessage, 'Message copied');
  });

  test('read aloud action carries text and snackbar copy', () {
    final effect = coordinator.readAloud(presentation);

    expect(effect, isA<ReadAloudMessageActionEffect>());
    expect((effect as ReadAloudMessageActionEffect).text, 'hello');
    expect(effect.snackbarMessage, 'Reading aloud');
  });

  test('pause action carries pause feedback only', () {
    final effect = coordinator.pauseStream(presentation);

    expect(effect, isA<PauseStreamMessageActionEffect>());
    expect(
      (effect as PauseStreamMessageActionEffect).snackbarMessage,
      'Stream pause requested',
    );
  });

  test('inspect and forward actions preserve message and target', () {
    const target = NavivoxProfileContact(
      serverId: 'gateway-1',
      profileId: 'profile-1',
      displayName: 'Profile 1',
      serverLabel: 'Gateway',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
    );

    final inspect = coordinator.inspectRunRecord(message);
    final forward = coordinator.forward(message, target);

    expect(inspect, isA<InspectRunRecordMessageActionEffect>());
    expect((inspect as InspectRunRecordMessageActionEffect).message, message);
    expect(forward, isA<ForwardMessageActionEffect>());
    expect((forward as ForwardMessageActionEffect).message, message);
    expect(forward.target, target);
  });
}
