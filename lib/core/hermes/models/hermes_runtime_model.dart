import '../../protocol/wing_json.dart';

/// Bounded public metadata from one advertised `/v1/models` entry.
///
/// Hermes exposes the primary runtime model plus optional route aliases. Wing
/// retains only their public identifiers and routing relationship; permissions
/// and unknown provider payloads are discarded.
class HermesRuntimeModel {
  const HermesRuntimeModel({
    required this.id,
    this.root = '',
    this.parent = '',
  });

  factory HermesRuntimeModel.fromJson(Map<String, Object?> json) {
    final id = _firstBounded(json, const ['id', 'root', 'model', 'name']);
    return HermesRuntimeModel(
      id: id,
      root: _bounded(wingStringFromJson(json['root'], fallback: id), 120),
      parent: _bounded(wingStringFromJson(json['parent'], fallback: ''), 120),
    );
  }

  final String id;
  final String root;
  final String parent;

  bool get isRouteAlias => root.isNotEmpty && root != id;
}

String _firstBounded(Map<String, Object?> json, List<String> fields) {
  for (final field in fields) {
    final value = wingOptionalStringFromJson(json[field]);
    if (value != null && value.trim().isNotEmpty) {
      return _bounded(value, 120);
    }
  }
  return '';
}

String _bounded(String value, int limit) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= limit) return normalized;
  return '${normalized.substring(0, limit - 1)}…';
}
