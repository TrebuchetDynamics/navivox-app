import '../../protocol/wing_json.dart';

/// Bounded public metadata from one installed `/v1/skills` entry.
class HermesSkill {
  const HermesSkill({
    required this.name,
    this.description = '',
    this.category = '',
  });

  factory HermesSkill.fromJson(Map<String, Object?> json) {
    return HermesSkill(
      name: _bounded(wingStringFromJson(json['name'], fallback: ''), 120),
      description: _bounded(
        wingStringFromJson(json['description'], fallback: ''),
        1000,
      ),
      category: _bounded(
        wingStringFromJson(json['category'], fallback: ''),
        80,
      ),
    );
  }

  final String name;
  final String description;
  final String category;
}

String _bounded(String value, int limit) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= limit) return normalized;
  return '${normalized.substring(0, limit - 1)}…';
}
