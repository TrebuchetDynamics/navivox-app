import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GOAL_STATE preserves Hermes readiness caveats and blockers', () {
    final text = File('GOAL_STATE.md').readAsStringSync();

    for (final snippet in [
      'Active goal: **become a Hermes Agent mobile app with continuous voice\nsupport**',
      '**1016 tests pass**',
      '453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a',
      'The APK hash is artifact identity only',
      'docs/runbooks/android/live-mic-smoke.md',
      'scripts/audit_hermes_readiness.sh',
      'npm run hermes:readiness-audit',
      'contract suite (27 pass)',
      'Strict readiness now uses automated Android\n   voice-loop receipt coverage',
      'instead of a human-spoken physical mic ship gate',
      'Provider-backed Hermes text plus deterministic transcript voice is covered',
      'Completion verdict: NOT COMPLETE',
      'Hermes server-audio, deferred-surface, or missing automated\n   receipt blockers remain',
      '`gh workflow list` shows `Hermes platform smoke`',
      'platform:workflow-smoke` now dispatches/watches the published `Hermes platform\n   smoke` workflow',
      'warning not to promote proxy',
      'tests, APK hashes, configured Hermes home, workflow YAML',
      '`build/receipts/hermes-platform-workflow.json` records a current watched\n   successful run',
      'Windows desktop, iOS simulator, and macOS desktop jobs and\n   artifacts',
      'Android live-mic runbook, plus the Android voice-readiness',
      'strict readiness audit after future Android receipts',
      'not\n   to promote a single Android helper receipt or proxy evidence',
      'KVM-backed `fractal_test` launch became\n   responsive long enough for `npm run android:voice-smoke`',
      '`npm run android:live-mic-prep` to pass',
      'install/launch/mic-grant\n   prep',
      'That remains readiness and deterministic\n   transcript/TTS loop evidence only',
      'Hermes home presence remains informational only',
      'Real spoken Android microphone smoke',
      'Windows, iOS, and macOS host-platform runner evidence is now captured by\n  `build/receipts/hermes-platform-workflow.json`',
      'The platform workflow is published and visible remotely as `Hermes platform\n  smoke`',
      'Hermes realtime/server audio',
      'not-whole-goal-completion caveats',
      'Provider-backed Hermes web text and transcript-voice smoke now passes',
      'still does not prove physical microphone\ncapture or Hermes realtime/server audio',
      'not real spoken-audio\nreceipts',
    ]) {
      expect(text, contains(snippet), reason: snippet);
    }
  });
}
