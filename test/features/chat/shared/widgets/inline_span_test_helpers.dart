import 'package:flutter/painting.dart';

/// Finds the first [TextSpan] whose direct text equals [text].
///
/// Shared by chat widget tests that assert rich text highlighting without
/// coupling each test file to the recursive InlineSpan traversal boilerplate.
TextSpan? spanForInlineText(InlineSpan root, String text) {
  if (root is TextSpan) {
    if (root.text == text) return root;
    for (final child in root.children ?? const <InlineSpan>[]) {
      final match = spanForInlineText(child, text);
      if (match != null) return match;
    }
  }
  return null;
}
