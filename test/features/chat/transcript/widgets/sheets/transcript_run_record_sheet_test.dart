import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_run_record_sheet.dart';

import '../../shared/transcript_test_scaffold.dart';
import '../../shared/transcript_test_fixtures.dart';

void main() {
  testWidgets(
    'renders redacted run record transcript, voice, tool, and usage rows',
    (tester) async {
      await tester.pumpWidget(
        transcriptTestScaffold(
          TranscriptRunRecordSheet(record: transcriptRunRecordSnapshot()),
        ),
      );

      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('req-run-record'), findsOneWidget);
      expect(find.text('s-run-record'), findsOneWidget);
      expect(find.text('completed'), findsOneWidget);
      expect(find.text('Provider usage'), findsOneWidget);
      expect(find.text('Provider cost'), findsOneWidget);
      expect(find.text('unknown'), findsWidgets);
      expect(find.text('Device transcript'), findsOneWidget);
      expect(find.text('transcribed voice command'), findsWidgets);
      expect(find.textContaining('raw audio not stored'), findsOneWidget);
      expect(find.text('read_file'), findsOneWidget);
      expect(find.textContaining('artifact://readme'), findsOneWidget);
    },
  );
}
