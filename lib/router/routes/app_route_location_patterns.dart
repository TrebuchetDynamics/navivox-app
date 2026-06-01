/// Pure path-shape checks used by route helpers and shell presentation.
///
/// These helpers intentionally ignore query strings and fragments while keeping
/// path segment counts explicit, so partial routes are not mistaken for detail
/// screens.
class AppRouteLocationPattern {
  const AppRouteLocationPattern._();

  static String pathOnly(String location) {
    return AppRouteLocationView.parse(location).path;
  }

  static bool hasPathPrefix({
    required String location,
    required String pathPrefix,
  }) {
    return AppRouteLocationView.parse(location).hasPathPrefix(pathPrefix);
  }

  static bool hasExactPathSegments({
    required String location,
    required List<String> expectedSegments,
  }) {
    return AppRouteLocationView.parse(
      location,
    ).hasExactPathSegments(expectedSegments);
  }
}

/// Parsed route-location shape used for matching app-owned routes.
///
/// Query strings and fragments are discarded. Segment comparisons use decoded
/// [Uri.pathSegments] when parsing succeeds, which keeps encoded slash values
/// inside a route parameter from creating extra route segments.
class AppRouteLocationView {
  const AppRouteLocationView._({required this.path, required this.segments});

  final String path;
  final List<String> segments;

  static AppRouteLocationView parse(String location) {
    try {
      final uri = Uri.parse(location);
      return AppRouteLocationView._(path: uri.path, segments: uri.pathSegments);
    } on FormatException {
      final fallbackPath = _fallbackPathOnly(location);
      return AppRouteLocationView._(
        path: fallbackPath,
        segments: _fallbackPathSegments(fallbackPath),
      );
    }
  }

  bool hasPathPrefix(String pathPrefix) {
    return path == pathPrefix || path.startsWith('$pathPrefix/');
  }

  bool hasExactPathSegments(List<String> expectedSegments) {
    if (segments.length != expectedSegments.length) return false;
    for (var index = 0; index < expectedSegments.length; index += 1) {
      final expected = expectedSegments[index];
      final actual = segments[index];
      if (expected.isNotEmpty && actual != expected) return false;
      if (expected.isEmpty && actual.isEmpty) return false;
    }
    return true;
  }

  static List<String> _fallbackPathSegments(String path) {
    return path.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  static String _fallbackPathOnly(String location) {
    return location.split(RegExp('[?#]')).first;
  }
}
