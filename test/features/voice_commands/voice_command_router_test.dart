import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice_commands/core/needle_engine.dart';
import 'package:navivox/features/voice_commands/models/voice_command.dart';
import 'package:navivox/features/voice_commands/services/voice_command_router.dart';
import 'package:navivox/features/voice_commands/services/voice_command_validator.dart';

class _ScriptedEngine implements NeedleEngineApi {
  _ScriptedEngine(this.responses);

  final List<Future<String> Function()> responses;
  int calls = 0;
  bool loaded = false;

  @override
  bool get isLoaded => loaded;

  @override
  Future<void> load(String modelDir) async => loaded = true;

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) {
    return responses[calls++ % responses.length]();
  }

  @override
  Future<void> unload() async => loaded = false;
}

const _statusCall =
    '{"success": true, "response": "", "function_calls": '
    '[{"name": "show_status", "arguments": {}}]}';

VoiceCommandRouter _router(
  NeedleEngineApi engine, {
  Duration timeout = const Duration(milliseconds: 1500),
}) => VoiceCommandRouter(
  engine: engine,
  modelDirProvider: () async => '/model',
  contextProvider: () =>
      const VoiceCommandContext(sessionTitles: [], voiceNames: []),
  timeout: timeout,
);

void main() {
  test('routes a valid call to a snapped result', () async {
    final router = _router(_ScriptedEngine([() async => _statusCall]));
    final result = await router.route('is the agent connected');
    expect(result!.command, VoiceCommandId.showStatus);
    expect(result.transcript, 'is the agent connected');
  });

  test('uninstalled model returns null without touching the engine', () async {
    final engine = _ScriptedEngine([() async => _statusCall]);
    final router = VoiceCommandRouter(
      engine: engine,
      modelDirProvider: () async => null,
      contextProvider: () =>
          const VoiceCommandContext(sessionTitles: [], voiceNames: []),
    );
    expect(await router.route('is the agent connected'), isNull);
    expect(engine.calls, 0);
  });

  test('timeout falls through and does not count toward suspension', () async {
    final never = Completer<String>();
    final router = _router(
      _ScriptedEngine([() => never.future]),
      timeout: const Duration(milliseconds: 50),
    );
    expect(await router.route('anything'), isNull);
    expect(router.suspended, isFalse);
  });

  test('three engine failures suspend the router', () async {
    final router = _router(
      _ScriptedEngine([() async => throw const NeedleEngineException('boom')]),
    );
    for (var i = 0; i < 3; i++) {
      expect(await router.route('x'), isNull);
    }
    expect(router.suspended, isTrue);
    // Suspended router short-circuits even with a healthy engine call queue.
    expect(await router.route('is the agent connected'), isNull);
  });

  test('concurrent route returns null for the second caller', () async {
    final gate = Completer<String>();
    final engine = _ScriptedEngine([() => gate.future]);
    final router = _router(engine);
    final first = router.route('one');
    expect(await router.route('two'), isNull);
    gate.complete(_statusCall);
    expect((await first)!.command, VoiceCommandId.showStatus);
    expect(engine.calls, 1);
  });
}
