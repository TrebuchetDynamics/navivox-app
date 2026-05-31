import 'package:flutter/widgets.dart';

import '../../shared/transcript_widget_test_host.dart';

/// Optional wrapper for a focused transcript message widget under test.
typedef TranscriptMessageHostWrapper = Widget Function(Widget messageWidget);

/// Hosts transcript message widgets in the shared feature-test shell.
Widget transcriptMessageTestHost(
  Widget messageWidget, {
  TranscriptMessageHostWrapper? wrap,
}) {
  return transcriptWidgetTestHost(wrap?.call(messageWidget) ?? messageWidget);
}
