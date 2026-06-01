/// Pure path-shape checks used by route helpers and shell presentation.
///
/// These helpers intentionally ignore query strings and fragments while keeping
/// path segment counts explicit, so partial routes are not mistaken for detail
/// screens.
class AppRouteLocationPattern {
  const AppRouteLocationPattern._();

  static String pathOnly(String location) {
    try {
      return Uri.parse(location).path;
    } on FormatException {
      return _fallbackPathOnly(location);
    }
  }

  static bool hasPathPrefix({
    required String location,
    required String pathPrefix,
  }) {
    final path = pathOnly(location);
    return path == pathPrefix || path.startsWith('$pathPrefix/');
  }

  static bool hasExactPathSegments({
    required String location,
    required List<String> expectedSegments,
  }) {
    final actual = _pathSegments(location);
    if (actual.length != expectedSegments.length) return false;
    for (var index = 0; index < expectedSegments.length; index += 1) {
      final expected = expectedSegments[index];
      if (expected.isNotEmpty && actual[index] != expected) return false;
      if (expected.isEmpty && actual[index].isEmpty) return false;
    }
    return true;
  }

  static List<String> _pathSegments(String location) {
    try {
      return Uri.parse(location).pathSegments;
    } on FormatException {
      return _fallbackPathOnly(
        location,
      ).split('/').where((segment) => segment.isNotEmpty).toList();
    }
  }

  static String _fallbackPathOnly(String location) {
    return location.split(RegExp('[?#]')).first;
  }
}
