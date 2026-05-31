import 'package:flutter_test/flutter_test.dart';

/// Captures the shared Transcript attachment sheet action callbacks.
class TranscriptAttachmentActions {
  bool uploadedFile = false;
  bool pickedMedia = false;
  bool openedWorkspace = false;

  void uploadFile() => uploadedFile = true;

  void pickPhotoOrVideo() => pickedMedia = true;

  void openWorkspace() => openedWorkspace = true;
}

/// Exercises the shared Transcript attachment sheet and verifies each action.
Future<void> expectTranscriptAttachmentSheetActions(
  WidgetTester tester,
  TranscriptAttachmentActions actions,
) async {
  await tester.tap(find.byTooltip('Attach'));
  await tester.pumpAndSettle();

  expect(find.text('Share'), findsOneWidget);
  expect(find.text('Upload file'), findsOneWidget);
  expect(find.text('Photo or video'), findsOneWidget);
  expect(find.text('Workspace file'), findsOneWidget);

  await tester.tap(find.text('Upload file'));
  await tester.pumpAndSettle();
  expect(actions.uploadedFile, isTrue);

  await tester.tap(find.byTooltip('Attach'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Photo or video'));
  await tester.pumpAndSettle();
  expect(actions.pickedMedia, isTrue);

  await tester.tap(find.byTooltip('Attach'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Workspace file'));
  await tester.pumpAndSettle();
  expect(actions.openedWorkspace, isTrue);
}
