import '../presentation/composer/transcript_composer_presentation.dart';

final class TranscriptComposerShareCoordinator {
  const TranscriptComposerShareCoordinator();

  TranscriptComposerShareEffect handleOption({
    required TranscriptComposerShareOptionKind kind,
    required bool hasUploadFileCallback,
    required bool hasPickPhotoOrVideoCallback,
    required bool hasOpenWorkspaceCallback,
  }) {
    return switch (kind) {
      TranscriptComposerShareOptionKind.uploadFile =>
        hasUploadFileCallback
            ? const TranscriptComposerShareEffect.invokeUploadFile()
            : const TranscriptComposerShareEffect.showUnavailable(
                title: 'File upload unavailable',
                message:
                    'Gormes has not advertised a Navivox upload endpoint yet. Use text or workspace references for now.',
              ),
      TranscriptComposerShareOptionKind.photoOrVideo =>
        hasPickPhotoOrVideoCallback
            ? const TranscriptComposerShareEffect.invokePickPhotoOrVideo()
            : const TranscriptComposerShareEffect.showUnavailable(
                title: 'Photo upload unavailable',
                message:
                    'Photo and video picking is ready to plug into the upload endpoint once Gormes enables uploads.',
              ),
      TranscriptComposerShareOptionKind.workspaceFile =>
        hasOpenWorkspaceCallback
            ? const TranscriptComposerShareEffect.invokeOpenWorkspace()
            : const TranscriptComposerShareEffect.showUnavailable(
                title: 'Workspace browser unavailable',
                message:
                    'Select a profile contact with workspace roots before browsing workspace files.',
              ),
    };
  }
}

sealed class TranscriptComposerShareEffect {
  const TranscriptComposerShareEffect._();

  const factory TranscriptComposerShareEffect.invokeUploadFile() =
      InvokeTranscriptComposerUploadFileEffect;
  const factory TranscriptComposerShareEffect.invokePickPhotoOrVideo() =
      InvokeTranscriptComposerPickPhotoOrVideoEffect;
  const factory TranscriptComposerShareEffect.invokeOpenWorkspace() =
      InvokeTranscriptComposerOpenWorkspaceEffect;
  const factory TranscriptComposerShareEffect.showUnavailable({
    required String title,
    required String message,
  }) = ShowTranscriptComposerShareUnavailableEffect;
}

final class InvokeTranscriptComposerUploadFileEffect
    extends TranscriptComposerShareEffect {
  const InvokeTranscriptComposerUploadFileEffect() : super._();
}

final class InvokeTranscriptComposerPickPhotoOrVideoEffect
    extends TranscriptComposerShareEffect {
  const InvokeTranscriptComposerPickPhotoOrVideoEffect() : super._();
}

final class InvokeTranscriptComposerOpenWorkspaceEffect
    extends TranscriptComposerShareEffect {
  const InvokeTranscriptComposerOpenWorkspaceEffect() : super._();
}

final class ShowTranscriptComposerShareUnavailableEffect
    extends TranscriptComposerShareEffect {
  const ShowTranscriptComposerShareUnavailableEffect({
    required this.title,
    required this.message,
  }) : super._();

  final String title;
  final String message;
}
