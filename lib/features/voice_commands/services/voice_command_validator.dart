import '../core/needle_result.dart';
import '../models/voice_command.dart';
import 'voice_command_catalog.dart';

/// Live snap candidates. Supplied fresh per validation so session titles and
/// installed voices are never cached stale.
class VoiceCommandContext {
  const VoiceCommandContext({
    required this.sessionTitles,
    required this.voiceNames,
  });

  final List<String> sessionTitles;
  final List<String> voiceNames;
}

/// Guardrail layer: unknown tool or unsnappable args return null, which the
/// router treats as fallthrough-to-Hermes. Nothing here throws.
abstract final class VoiceCommandValidator {
  static VoiceRouteResult? validate(
    NeedleFunctionCall call, {
    required String transcript,
    required VoiceCommandContext context,
  }) {
    final id = VoiceCommandCatalog.byWireName(call.name);
    if (id == null) return null;
    final args = <String, Object?>{};
    switch (id) {
      case VoiceCommandId.navigateToScreen:
        final screen =
            _snapEnum(call.arguments['screen'], const ['hermes', 'settings']);
        if (screen == null) return null;
        args['screen'] = screen;
      case VoiceCommandId.toggleContinuousMode:
        final enabled = _snapBool(call.arguments['enabled']);
        if (enabled == null) return null;
        args['enabled'] = enabled;
      case VoiceCommandId.setSpeechRate:
        final rate = _snapRate(call.arguments['rate']);
        if (rate == null) return null;
        args['rate'] = rate;
      case VoiceCommandId.switchSession:
        final title =
            _snapFuzzy(call.arguments['session_name'], context.sessionTitles);
        if (title == null) return null;
        args['session_name'] = title;
      case VoiceCommandId.setTtsVoice:
        final voice = _snapFuzzy(call.arguments['voice'], context.voiceNames);
        if (voice == null) return null;
        args['voice'] = voice;
      case VoiceCommandId.showStatus:
      case VoiceCommandId.stopVoiceRun:
      case VoiceCommandId.startVoiceRun:
      case VoiceCommandId.newSession:
        break;
    }
    return VoiceRouteResult(
      command: id,
      args: args,
      tier: _tierFor(id, args),
      transcript: transcript,
    );
  }

  static VoiceCommandTier _tierFor(VoiceCommandId id, Map<String, Object?> args) {
    switch (id) {
      case VoiceCommandId.navigateToScreen:
      case VoiceCommandId.showStatus:
      case VoiceCommandId.stopVoiceRun:
        return VoiceCommandTier.instant;
      case VoiceCommandId.toggleContinuousMode:
        return args['enabled'] == false
            ? VoiceCommandTier.instant
            : VoiceCommandTier.confirm;
      case VoiceCommandId.startVoiceRun:
      case VoiceCommandId.newSession:
      case VoiceCommandId.switchSession:
      case VoiceCommandId.setTtsVoice:
      case VoiceCommandId.setSpeechRate:
        return VoiceCommandTier.confirm;
    }
  }

  static String _normalize(Object? value) =>
      '$value'.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String? _snapEnum(Object? raw, List<String> allowed) {
    if (raw == null) return null;
    final v = _normalize(raw);
    if (allowed.contains(v)) return v;
    final hits = allowed
        .where((a) => v.split(' ').contains(a) || a.split(' ').contains(v))
        .toList();
    return hits.length == 1 ? hits.single : null;
  }

  static bool? _snapBool(Object? raw) {
    if (raw is bool) return raw;
    switch (_normalize(raw)) {
      case 'true' || 'on':
        return true;
      case 'false' || 'off':
        return false;
      default:
        return null;
    }
  }

  static double? _snapRate(Object? raw) {
    final value = raw is num ? raw.toDouble() : double.tryParse('$raw'.trim());
    if (value == null) return null;
    return value.clamp(0.25, 3.0);
  }

  static String? _snapFuzzy(Object? raw, List<String> candidates) {
    if (raw == null) return null;
    final v = _normalize(raw);
    if (v.isEmpty) return null;
    final exact =
        candidates.where((c) => _normalize(c) == v).toList();
    if (exact.length == 1) return exact.single;
    final partial = candidates
        .where((c) =>
            _normalize(c).contains(v) || v.contains(_normalize(c)))
        .toList();
    return partial.length == 1 ? partial.single : null;
  }
}
