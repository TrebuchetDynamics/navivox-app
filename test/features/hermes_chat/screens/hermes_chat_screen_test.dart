import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/models/hermes_chat_turn.dart';
import 'package:navivox/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:navivox/shared/voice/text_to_speech_service.dart';

import '../../shared/fakes/voice_capture_service_fakes.dart';
import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

Widget _wrap(
  FakeHermesChannel channel, {
  Widget Function()? screenBuilder,
  FakeHermesEndpointStore? endpointStore,
}) {
  return ProviderScope(
    overrides: [
      hermesChannelProvider.overrideWithValue(channel),
      if (endpointStore != null)
        hermesEndpointStoreProvider.overrideWithValue(endpointStore),
    ],
    child: MaterialApp(home: screenBuilder?.call() ?? const HermesChatScreen()),
  );
}

void main() {
  testWidgets(
    'shows a connect form when disconnected and connects with entered values',
    (tester) async {
      final channel = FakeHermesChannel.disconnected();
      await tester.pumpWidget(_wrap(channel));

      expect(
        find.byKey(const ValueKey('hermes-base-url-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-connect-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('hermes-transcript')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('hermes-base-url-field')),
        'http://10.0.2.2:8642',
      );
      await tester.enterText(
        find.byKey(const ValueKey('hermes-api-key-field')),
        'secret',
      );
      await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
      await tester.pumpAndSettle();

      expect(channel.connectCalls, hasLength(1));
      expect(channel.connectCalls.single.baseUrl, 'http://10.0.2.2:8642');
      expect(channel.connectCalls.single.apiKey, 'secret');
      expect(find.byKey(const ValueKey('hermes-transcript')), findsOneWidget);
    },
  );

  testWidgets('shows the connect error message when connecting failed', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'Hermes API rejected the request credentials',
    );
    await tester.pumpWidget(_wrap(channel));

    expect(
      find.text('Hermes API rejected the request credentials'),
      findsOneWidget,
    );
  });

  testWidgets('sending composer text appends the turn and clears the field', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'hello hermes',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('hello hermes'), findsOneWidget);
    expect(find.text('echo: hello hermes'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets(
    'tapping the mic button captures and submits a voice transcript',
    (tester) async {
      final channel = FakeHermesChannel();
      await tester.pumpWidget(
        _wrap(
          channel,
          screenBuilder: () => HermesChatScreen(
            voiceCaptureServiceOverride: successfulVoiceCaptureService(
              transcript: 'turn the lights on',
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
      await tester.pumpAndSettle();

      expect(channel.sentVoiceTranscripts, ['turn the lights on']);
      expect(find.text('turn the lights on'), findsOneWidget);
      expect(find.text('echo: turn the lights on'), findsOneWidget);
    },
  );

  testWidgets(
    'continuous voice speaks the reply then automatically re-arms capture',
    (tester) async {
      final channel = FakeHermesChannel();
      final tts = FakeTextToSpeechService();
      final captures = QueueVoiceCaptureService([
        testVoiceCapture('first question'),
        testVoiceCapture('second question'),
      ]);
      await tester.pumpWidget(
        _wrap(
          channel,
          screenBuilder: () => HermesChatScreen(
            voiceCaptureServiceOverride: captures,
            textToSpeechServiceOverride: tts,
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('hermes-continuous-voice-switch')),
      );
      await tester.pumpAndSettle();

      expect(channel.sentVoiceTranscripts, [
        'first question',
        'second question',
      ]);
      expect(tts.spoken, ['echo: first question', 'echo: second question']);
    },
  );

  testWidgets('saves the endpoint to the store after a successful connect', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore();
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://10.0.2.2:8642',
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-api-key-field')),
      'secret',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    expect(store.saveCalls, hasLength(1));
    expect(store.saveCalls.single.baseUrl, 'http://10.0.2.2:8642');
    expect(store.saveCalls.single.apiKey, 'secret');
  });

  testWidgets('does not save to the store when connecting fails', (
    tester,
  ) async {
    final channel = _FailingConnectHermesChannel();
    final store = FakeHermesEndpointStore();
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://10.0.2.2:8642',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    expect(store.saveCalls, isEmpty);
  });

  testWidgets('disconnect clears the store and returns to the connect form', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(baseUrl: 'http://10.0.2.2:8642'),
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-button')));
    await tester.pumpAndSettle();

    expect(store.clearCalls, 1);
    expect(find.byKey(const ValueKey('hermes-connect-button')), findsOneWidget);
  });

  testWidgets('renders a pending approval and answers approve/deny', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Run rm -rf /tmp/scratch?',
        risk: 'high',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
    expect(find.text('Run rm -rf /tmp/scratch?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.once},
    ]);
    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
  });

  testWidgets('denying an approval answers with the deny decision', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Run rm -rf /tmp/scratch?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-deny')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.deny},
    ]);
  });

  testWidgets('approving for the session answers with the session decision', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Read files in the workspace?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-session')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.session},
    ]);
  });

  testWidgets('shows a stop control while a turn is streaming and stops it', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    expect(find.byKey(const ValueKey('hermes-stop-button')), findsNothing);

    channel.beginStreamingTurn('keep going forever');
    // A streaming turn renders a perpetual progress indicator, so pump a
    // bounded number of frames instead of pumpAndSettle (which would hang).
    await tester.pump();

    expect(find.byKey(const ValueKey('hermes-stop-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-stop-button')));
    await tester.pump();

    expect(channel.stopActiveTurnCalls, 1);
  });

  testWidgets('renders a tool-call turn as a status card, not plain text', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.addToolCallTurn(
      const HermesToolCall(name: 'bash', status: 'running', preview: 'ls -la'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-tool-turn-tool-0')),
      findsOneWidget,
    );
    expect(find.text('bash'), findsOneWidget);
    expect(find.text('ls -la'), findsOneWidget);
    // Not rendered as a plain chat bubble alongside user/assistant text.
    expect(find.text('tool.started: bash'), findsNothing);
  });
}

class _FailingConnectHermesChannel extends FakeHermesChannel {
  _FailingConnectHermesChannel()
    : super(status: HermesConnectionStatus.disconnected);

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    // Connecting fails; state stays disconnected/error rather than connected.
  }
}
