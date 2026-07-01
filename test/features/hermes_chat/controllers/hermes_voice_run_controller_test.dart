import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/voice/models/navivox_voice_run.dart';
import 'package:navivox/features/hermes_chat/controllers/hermes_voice_run_controller.dart';
import 'package:navivox/shared/voice/voice_capture_failures.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import '../../chat/shared/voice/voice_recovery_test_fixtures.dart';
import '../../shared/fakes/voice_capture_service_fakes.dart';
import '../support/fake_hermes_channel.dart';

void main() {
  test('startCapture records the active voice run id', () {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceRunController();

    final voiceRunId = controller.startCapture(channel);

    expect(controller.pendingVoiceRunId, voiceRunId);
    expect(channel.state.activeVoiceRun?.id, voiceRunId);
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.recording,
    );
  });

  test('captureFailed maps timeout copy, fails run, and clears pending id', () {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceRunController();
    final voiceRunId = controller.startCapture(channel);

    final result = controller.captureFailed(
      channel,
      const VoiceCaptureTimeout(),
    );

    expect(result.reason, 'Voice capture timed out.');
    expect(result.runtimeVoiceDisabledReason, isNull);
    expect(controller.pendingVoiceRunId, isNull);
    expect(
      channel.state.voiceRuns[voiceRunId]?.status,
      NavivoxVoiceRunStatus.failed,
    );
    expect(
      channel.state.voiceRuns[voiceRunId]?.reason,
      'Voice capture timed out.',
    );
  });

  test('captureFailed canonicalizes runtime device STT failures', () {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceRunController()..startCapture(channel);

    final result = controller.captureFailed(
      channel,
      const DeviceSpeechUnavailable(microphonePermissionDeniedReason),
    );

    expect(result.reason, microphonePermissionDeniedReason);
    expect(result.runtimeVoiceDisabledReason, microphonePermissionDeniedReason);
    expect(
      controller.runtimeVoiceDisabledReason,
      microphonePermissionDeniedReason,
    );
    expect(channel.state.latestVoiceRun?.status, NavivoxVoiceRunStatus.failed);
  });

  test('clearRuntimeVoiceDisabledReason resets session voice blocker', () {
    final controller = HermesVoiceRunController()
      ..runtimeVoiceDisabledReason = deviceSttUnavailableReason;

    controller.clearRuntimeVoiceDisabledReason();

    expect(controller.runtimeVoiceDisabledReason, isNull);
  });

  test('captureSucceeded cancels a started voice run for local commands', () {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceRunController();
    final voiceRunId = controller.startCapture(channel);
    final localCommands = <String>[];

    final result = controller.captureSucceeded(
      channel,
      testVoiceCapture('navi cancel'),
      handleLocalCommand: (transcript) {
        localCommands.add(transcript);
        return true;
      },
    );

    expect(localCommands, ['navi cancel']);
    expect(result.handledLocalCommand, isTrue);
    expect(result.scheduleAutoSendFor, isNull);
    expect(controller.pendingVoiceRunId, isNull);
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(
      channel.state.voiceRuns[voiceRunId]?.status,
      NavivoxVoiceRunStatus.cancelled,
    );
    expect(channel.state.voiceRuns[voiceRunId]?.reason, 'local voice command');
  });

  test(
    'captureSucceeded stages transcript and requests auto-send scheduling',
    () {
      final channel = FakeHermesChannel();
      final controller = HermesVoiceRunController();

      final result = controller.captureSucceeded(
        channel,
        testVoiceCapture('turn the lights on'),
        handleLocalCommand: (_) => false,
      );

      final voiceRunId = result.scheduleAutoSendFor;
      expect(voiceRunId, isNotNull);
      expect(controller.pendingVoiceRunId, voiceRunId);
      expect(controller.notice, 'Sending...');
      expect(channel.sentVoiceTranscripts, isEmpty);
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.pendingSend,
      );
      expect(
        channel.state.voiceRuns[voiceRunId]?.transcript,
        'turn the lights on',
      );
    },
  );

  test('autoSendIfPending submits the matching pending voice run', () {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceRunController();
    final staged = controller.captureSucceeded(
      channel,
      testVoiceCapture('turn the lights on'),
      handleLocalCommand: (_) => false,
    );

    final result = controller.autoSendIfPending(
      channel,
      staged.scheduleAutoSendFor!,
    );

    expect(result.submitted, isTrue);
    expect(controller.pendingVoiceRunId, isNull);
    expect(controller.notice, isNull);
    expect(channel.sentVoiceTranscripts, ['turn the lights on']);
    expect(
      channel.state.voiceRuns[staged.scheduleAutoSendFor]?.status,
      NavivoxVoiceRunStatus.completed,
    );
  });

  test('cancelPending cancels active pending voice run with operator copy', () {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceRunController();
    final staged = controller.captureSucceeded(
      channel,
      testVoiceCapture('check status'),
      handleLocalCommand: (_) => false,
    );

    final result = controller.cancelPending(channel);

    expect(result.cancelledVoiceRunId, staged.scheduleAutoSendFor);
    expect(controller.pendingVoiceRunId, isNull);
    expect(controller.notice, 'Voice turn cancelled before server commit.');
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(
      channel.state.latestVoiceRun?.status,
      NavivoxVoiceRunStatus.cancelled,
    );
  });
}
