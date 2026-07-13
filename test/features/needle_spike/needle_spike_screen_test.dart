import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/providers/needle_spike_providers.dart';
import 'package:navivox/features/needle_spike/screens/needle_spike_screen.dart';
import 'package:navivox/features/needle_spike/services/needle_engine.dart';
import 'package:navivox/features/needle_spike/services/needle_model_install_service.dart';

class _FakeEngine implements NeedleEngineApi {
  bool loaded = false;

  @override
  bool get isLoaded => loaded;

  @override
  Future<void> load(String modelDir) async {
    loaded = true;
  }

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) async {
    return '{"success": true, "response": "", "function_calls": '
        '[{"name": "show_status", "arguments": {}}], "total_time_ms": 42.0}';
  }

  @override
  Future<void> unload() async {}
}

void main() {
  testWidgets(
    'typed transcript produces a parsed tool call and scorecard tick',
    (tester) async {
      // Directory.systemTemp.createTemp uses dart:io's real (isolate-backed)
      // async file APIs, which never resolve inside a bare testWidgets pump
      // cycle — they need the real event loop that tester.runAsync provides.
      final tempDir = await tester.runAsync(
        () => Directory.systemTemp.createTemp('needle_screen'),
      );
      addTearDown(() => tempDir!.delete(recursive: true));
      // Pre-install a fake model so the screen goes straight to ready state.
      final install = NeedleModelInstallService(supportDirectory: tempDir!);
      final modelDir = Directory('${tempDir.path}/needle_spike/model')
        ..createSync(recursive: true);
      File('${modelDir.path}/config.json').writeAsStringSync('{}');
      File(
        '${tempDir.path}/needle_spike/.installed',
      ).writeAsStringSync(modelDir.path);

      // The screen's initState kicks off a real async File read (via
      // NeedleModelInstallService.installedModelDir) to check for an
      // installed model. That real dart:io async work only completes while
      // running inside tester.runAsync; a plain pump()/pumpAndSettle() call
      // outside of it will hang forever waiting on the isolate response.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              needleEngineProvider.overrideWithValue(_FakeEngine()),
              needleInstallServiceProvider.overrideWith((ref) async => install),
              needleVoiceCaptureFactoryProvider.overrideWithValue(() => null),
            ],
            child: const MaterialApp(home: NeedleSpikeScreen()),
          ),
        );
        // Yield to the real event loop long enough for the pending real IO
        // (installedModelDir's File.exists/readAsString) to be delivered.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('needle-transcript-field')),
        'is the agent connected',
      );
      await tester.tap(find.byKey(const Key('needle-run-button')));
      await tester.pumpAndSettle();

      // The result card and scorecard render below the 20-chip bank, which
      // pushes them out of the default test viewport. ListView only mounts
      // visible slivers, so scroll down before locating them.
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.textContaining('show_status'), findsOneWidget);
      expect(find.textContaining('wall'), findsOneWidget);

      await tester.tap(find.byKey(const Key('needle-verdict-correct')));
      await tester.pump();
      expect(find.textContaining('correct 1'), findsOneWidget);
    },
  );
}
