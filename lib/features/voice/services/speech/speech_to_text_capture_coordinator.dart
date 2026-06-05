import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/protocol/voice_unavailable_reason.dart';
import '../../../../shared/voice/voice_capture_failures.dart';
import 'speech_to_text_capture_policy.dart';

final class SpeechToTextCaptureCoordinator {
  const SpeechToTextCaptureCoordinator();

  String unavailableReasonForInitialize({
    required bool? permissionBeforeInitialize,
  }) {
    return permissionBeforeInitialize == false
        ? microphonePermissionDeniedReason
        : deviceSttUnavailableReason;
  }

  SpeechToTextTerminalStatusPlan terminalStatusPlan({
    required String status,
    required SpeechToTextSnapshot? latestTranscript,
  }) {
    if (!isTerminalSpeechToTextStatus(status)) {
      return const SpeechToTextTerminalStatusPlan.ignore();
    }
    final snapshot = latestTranscript;
    if (snapshot != null) {
      return SpeechToTextTerminalStatusPlan.complete(snapshot);
    }
    return const SpeechToTextTerminalStatusPlan.fail(
      SpeechToTextCaptureFailure('no transcript'),
    );
  }

  SpeechToTextSnapshot? latestUsableTranscript({
    required SpeechToTextSnapshot? current,
    required SpeechToTextSnapshot candidate,
  }) {
    return latestUsableSpeechToTextTranscript(
      current: current,
      candidate: candidate,
    );
  }

  SpeechToTextSnapshot completionTranscript({
    required SpeechToTextSnapshot terminalSnapshot,
    required SpeechToTextSnapshot? latestUsableSnapshot,
  }) {
    return completionSpeechToTextTranscript(
      terminalSnapshot: terminalSnapshot,
      latestUsableSnapshot: latestUsableSnapshot,
    );
  }

  Object normalizeError(Object error) {
    if (error is SpeechRecognitionError) {
      if (isNoTranscriptVoiceCaptureReason(error.errorMsg)) {
        return const SpeechToTextCaptureFailure('no transcript');
      }
      if (error.permanent) {
        return DeviceSpeechUnavailable(
          speechToTextDeviceUnavailableReasonFromMessage(error.errorMsg),
        );
      }
    }
    if (error is stt.ListenFailedException) {
      return DeviceSpeechUnavailable(
        speechToTextDeviceUnavailableReasonFromMessage(
          '${error.message ?? ''} ${error.details ?? ''}',
        ),
      );
    }
    return SpeechToTextCaptureFailure(error);
  }

  String errorDiagnostic(Object error) {
    if (error is SpeechRecognitionError) {
      return 'error errorMsg=${error.errorMsg} permanent=${error.permanent}';
    }
    return 'error=$error';
  }
}

sealed class SpeechToTextTerminalStatusPlan {
  const SpeechToTextTerminalStatusPlan._();

  const factory SpeechToTextTerminalStatusPlan.ignore() =
      IgnoreSpeechToTextTerminalStatusPlan;
  const factory SpeechToTextTerminalStatusPlan.complete(
    SpeechToTextSnapshot snapshot,
  ) = CompleteSpeechToTextTerminalStatusPlan;
  const factory SpeechToTextTerminalStatusPlan.fail(Object error) =
      FailSpeechToTextTerminalStatusPlan;
}

final class IgnoreSpeechToTextTerminalStatusPlan
    extends SpeechToTextTerminalStatusPlan {
  const IgnoreSpeechToTextTerminalStatusPlan() : super._();
}

final class CompleteSpeechToTextTerminalStatusPlan
    extends SpeechToTextTerminalStatusPlan {
  const CompleteSpeechToTextTerminalStatusPlan(this.snapshot) : super._();

  final SpeechToTextSnapshot snapshot;
}

final class FailSpeechToTextTerminalStatusPlan
    extends SpeechToTextTerminalStatusPlan {
  const FailSpeechToTextTerminalStatusPlan(this.error) : super._();

  final Object error;
}
