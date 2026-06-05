import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/transcript/actions/transcript_composer_share_coordinator.dart';
import 'package:navivox/features/chat/transcript/presentation/composer/transcript_composer_presentation.dart';

void main() {
  const coordinator = TranscriptComposerShareCoordinator();

  test('invokes available share callbacks', () {
    expect(
      coordinator.handleOption(
        kind: TranscriptComposerShareOptionKind.uploadFile,
        hasUploadFileCallback: true,
        hasPickPhotoOrVideoCallback: false,
        hasOpenWorkspaceCallback: false,
      ),
      isA<InvokeTranscriptComposerUploadFileEffect>(),
    );
    expect(
      coordinator.handleOption(
        kind: TranscriptComposerShareOptionKind.photoOrVideo,
        hasUploadFileCallback: false,
        hasPickPhotoOrVideoCallback: true,
        hasOpenWorkspaceCallback: false,
      ),
      isA<InvokeTranscriptComposerPickPhotoOrVideoEffect>(),
    );
    expect(
      coordinator.handleOption(
        kind: TranscriptComposerShareOptionKind.workspaceFile,
        hasUploadFileCallback: false,
        hasPickPhotoOrVideoCallback: false,
        hasOpenWorkspaceCallback: true,
      ),
      isA<InvokeTranscriptComposerOpenWorkspaceEffect>(),
    );
  });

  test('reports unavailable upload and workspace states explicitly', () {
    final upload = coordinator.handleOption(
      kind: TranscriptComposerShareOptionKind.uploadFile,
      hasUploadFileCallback: false,
      hasPickPhotoOrVideoCallback: false,
      hasOpenWorkspaceCallback: false,
    );
    expect(upload, isA<ShowTranscriptComposerShareUnavailableEffect>());
    expect(
      (upload as ShowTranscriptComposerShareUnavailableEffect).title,
      'File upload unavailable',
    );
    expect(upload.message, contains('Navivox upload endpoint'));

    final workspace = coordinator.handleOption(
      kind: TranscriptComposerShareOptionKind.workspaceFile,
      hasUploadFileCallback: false,
      hasPickPhotoOrVideoCallback: false,
      hasOpenWorkspaceCallback: false,
    );
    expect(workspace, isA<ShowTranscriptComposerShareUnavailableEffect>());
    expect(
      (workspace as ShowTranscriptComposerShareUnavailableEffect).message,
      contains('workspace roots'),
    );
  });
}
