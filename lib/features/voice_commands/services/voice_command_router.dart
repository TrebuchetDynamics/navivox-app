import 'dart:async';
import 'dart:convert';

import '../core/needle_engine.dart';
import '../core/needle_result.dart';
import '../models/voice_command.dart';
import 'voice_command_catalog.dart';
import 'voice_command_validator.dart';

/// Turns one transcript into at most one validated local command. Every
/// abnormal path returns null — the caller then routes to Hermes unchanged.
class VoiceCommandRouter {
  VoiceCommandRouter({
    required NeedleEngineApi engine,
    required Future<String?> Function() modelDirProvider,
    required VoiceCommandContext Function() contextProvider,
    this.timeout = const Duration(milliseconds: 1500),
  }) : _engine = engine,
       _modelDirProvider = modelDirProvider,
       _contextProvider = contextProvider;

  static const String optionsJson =
      '{"max_tokens": 128, "temperature": 0, "force_tools": true, '
      '"tool_rag_top_k": 0, "auto_handoff": false}';

  static const int _maxFailures = 3;

  final NeedleEngineApi _engine;
  final Future<String?> Function() _modelDirProvider;
  final VoiceCommandContext Function() _contextProvider;
  final Duration timeout;

  bool _busy = false;
  int _failures = 0;

  bool get suspended => _failures >= _maxFailures;

  Future<VoiceRouteResult?> route(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty || suspended || _busy) return null;
    _busy = true;
    try {
      final modelDir = await _modelDirProvider();
      if (modelDir == null) return null;
      final raw = await _complete(trimmed, modelDir).timeout(timeout);
      if (raw == null) return null;
      final parsed = NeedleResult.fromEngineJson(raw, wallLatencyMs: 0);
      if (!parsed.success) {
        _failures += 1;
        return null;
      }
      if (parsed.functionCalls.isEmpty) return null;
      return VoiceCommandValidator.validate(
        parsed.functionCalls.first,
        transcript: trimmed,
        context: _contextProvider(),
      );
    } on TimeoutException {
      return null;
    } on Exception {
      _failures += 1;
      return null;
    } finally {
      _busy = false;
    }
  }

  Future<String?> _complete(String transcript, String modelDir) async {
    if (!_engine.isLoaded) {
      await _engine.load(modelDir);
    }
    return _engine.complete(
      messagesJson: jsonEncode([
        {'role': 'user', 'content': transcript},
      ]),
      toolsJson: VoiceCommandCatalog.toolsJson,
      optionsJson: optionsJson,
    );
  }
}
