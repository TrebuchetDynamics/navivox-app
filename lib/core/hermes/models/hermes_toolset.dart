import '../../protocol/wing_json.dart';

/// Bounded public metadata from one advertised `/v1/toolsets` entry.
///
/// Only the deterministic inventory contract is retained. Unknown nested
/// fields, credentials, and configuration values are discarded.
class HermesToolset {
  const HermesToolset({
    required this.name,
    this.label = '',
    this.description = '',
    this.enabled = false,
    this.configured = false,
    this.tools = const [],
  });

  factory HermesToolset.fromJson(Map<String, Object?> json) {
    final tools =
        wingListFromJson(json['tools'])
            .whereType<String>()
            .map((tool) => _bounded(tool, 120))
            .where((tool) => tool.isNotEmpty)
            .toSet()
            .toList()
          ..sort(
            (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
          );
    return HermesToolset(
      name: _bounded(wingStringFromJson(json['name'], fallback: ''), 120),
      label: _bounded(wingStringFromJson(json['label'], fallback: ''), 160),
      description: _bounded(
        wingStringFromJson(json['description'], fallback: ''),
        1000,
      ),
      enabled: wingBoolFromJson(json['enabled']),
      configured: wingBoolFromJson(json['configured']),
      tools: List.unmodifiable(tools.take(64)),
    );
  }

  final String name;
  final String label;
  final String description;
  final bool enabled;
  final bool configured;
  final List<String> tools;

  String get displayName => label.isEmpty ? name : label;
}

String _bounded(String value, int limit) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= limit) return normalized;
  return '${normalized.substring(0, limit - 1)}…';
}
