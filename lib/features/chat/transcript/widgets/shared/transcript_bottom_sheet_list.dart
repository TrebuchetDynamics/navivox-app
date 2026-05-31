import 'package:flutter/material.dart';

/// Shared transcript bottom-sheet list chrome.
///
/// Keeps drag-handle sheets consistent across composer and message actions while
/// leaving each caller responsible for presentation-specific rows.
class TranscriptBottomSheetList extends StatelessWidget {
  const TranscriptBottomSheetList({
    required this.children,
    this.controller,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    super.key,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        controller: controller,
        shrinkWrap: true,
        padding: padding,
        children: children,
      ),
    );
  }
}
