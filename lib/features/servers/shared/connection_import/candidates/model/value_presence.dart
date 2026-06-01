part of '../../parser.dart';

/// The minimal values that make an import actionable by setup flows.
///
/// Profile metadata enriches a selected gateway, but cannot select or probe a
/// gateway by itself. A websocket endpoint is actionable because the parser
/// derives the HTTP base URL from valid ws/wss endpoints before constructing the
/// candidate.
class _ConnectionImportValuePresence {
  const _ConnectionImportValuePresence({
    required this.baseUrl,
    required this.token,
  });

  final String? baseUrl;
  final String? token;

  bool get hasActionableImport => baseUrl != null || token != null;

  bool get hasCompleteConnection => baseUrl != null && token != null;
}
