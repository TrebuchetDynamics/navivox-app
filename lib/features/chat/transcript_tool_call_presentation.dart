import '../../core/protocol/navivox_event.dart';

enum TranscriptToolCallStatusTone { active, success, failure, neutral }

class TranscriptToolArtifactPresentation {
  const TranscriptToolArtifactPresentation({
    required this.kind,
    required this.title,
    required this.summary,
  });

  factory TranscriptToolArtifactPresentation.fromArtifact(
    NavivoxToolArtifact artifact,
  ) {
    return TranscriptToolArtifactPresentation(
      kind: artifact.kind,
      title: artifact.title,
      summary: artifact.summary,
    );
  }

  final String kind;
  final String title;
  final String? summary;

  bool get showSummary => summary?.isNotEmpty == true;
}

class TranscriptToolCallPresentation {
  const TranscriptToolCallPresentation({
    required this.name,
    required this.statusLabel,
    required this.statusTone,
    required this.summary,
    required this.artifacts,
  });

  factory TranscriptToolCallPresentation.fromToolCall(
    NavivoxToolCall toolCall,
  ) {
    return TranscriptToolCallPresentation(
      name: toolCall.name,
      statusLabel: toolCall.status,
      statusTone: statusToneFor(toolCall.status),
      summary: toolCall.summary,
      artifacts: [
        for (final artifact in toolCall.artifacts)
          TranscriptToolArtifactPresentation.fromArtifact(artifact),
      ],
    );
  }

  final String name;
  final String statusLabel;
  final TranscriptToolCallStatusTone statusTone;
  final String summary;
  final List<TranscriptToolArtifactPresentation> artifacts;

  bool get showSummary => summary.isNotEmpty;

  static TranscriptToolCallStatusTone statusToneFor(String status) {
    return switch (status) {
      'started' => TranscriptToolCallStatusTone.active,
      'finished' => TranscriptToolCallStatusTone.success,
      'failed' => TranscriptToolCallStatusTone.failure,
      _ => TranscriptToolCallStatusTone.neutral,
    };
  }
}
