import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

import 'support/navivox_voice_run_test_support.dart';

void main() {
  test('creates a recording voice run for a profile contact', () {
    final run = recordingVoiceRun();

    expect(run.id, 'voice-1');
    expect(run.serverId, 'local');
    expect(run.profileId, 'mineru');
    expect(run.status, NavivoxVoiceRunStatus.recording);
    expect(run.transcriptSource, NavivoxTranscriptSource.device);
    expect(run.ttsStatus, NavivoxTtsStatus.unavailable);
    expect(run.isTerminal, isFalse);
  });

  test('moves a device transcript to pending send without losing metadata', () {
    final run = recordingVoiceRun().withDeviceTranscript(
      transcript: 'check status',
      duration: const Duration(milliseconds: 900),
      confidence: 0.91,
      updatedAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
    );

    expect(run.status, NavivoxVoiceRunStatus.pendingSend);
    expect(run.transcript, 'check status');
    expect(run.duration, const Duration(milliseconds: 900));
    expect(run.confidence, 0.91);
    expect(run.transcriptSource, NavivoxTranscriptSource.device);
  });

  test(
    'submitted completed cancelled and failed statuses are terminal-aware',
    () {
      final base = recordingVoiceRun().withDeviceTranscript(
        transcript: 'hello',
        duration: const Duration(seconds: 1),
        confidence: 1,
        updatedAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
      );

      expect(base.markSubmitted(requestId: 'req-1').isTerminal, isFalse);
      expect(base.markCompleted().isTerminal, isTrue);
      expect(base.markCancelled('cancelled before send').isTerminal, isTrue);
      expect(base.markFailed('microphone denied').isTerminal, isTrue);
      expect(
        navivoxVoiceRunStatusIsTerminal(NavivoxVoiceRunStatus.failed),
        isTrue,
      );
    },
  );

  test('completed transition does not keep stale terminal reason', () {
    final completedAfterFailure = recordingVoiceRun()
        .withDeviceTranscript(
          transcript: 'hello',
          duration: const Duration(seconds: 1),
          confidence: 1,
          updatedAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
        )
        .markFailed('gateway timeout')
        .markCompleted();

    expect(completedAfterFailure.status, NavivoxVoiceRunStatus.completed);
    expect(completedAfterFailure.reason, isNull);
  });
}
