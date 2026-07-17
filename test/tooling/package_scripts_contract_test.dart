import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package scripts expose Hermes and platform closeout helpers', () {
    final packageJson =
        jsonDecode(File('package.json').readAsStringSync())
            as Map<String, Object?>;
    final scripts = (packageJson['scripts'] as Map).cast<String, Object?>();

    const expectedScripts = {
      'hermes:live-smoke': './scripts/run_live_hermes_smoke.sh',
      'hermes:provider-smoke': './scripts/run_provider_hermes_smoke.sh',
      'hermes:provider-smoke:local':
          './scripts/run_local_configured_hermes_provider_smoke.sh',
      'hermes:server-audio-receipt':
          './scripts/record_hermes_server_audio_receipt.sh',
      'hermes:readiness-audit': './scripts/audit_hermes_readiness.sh',
      'android:voice-smoke': './scripts/run_android_voice_smoke.sh',
      'android:hermes-voice-loop-smoke':
          './scripts/run_android_hermes_voice_loop_smoke.sh',
      'android:durable-key-smoke': './scripts/run_android_durable_key_smoke.sh',
      'android:live-mic-prep': './scripts/prepare_android_live_mic_smoke.sh',
      'android:live-mic-receipt':
          './scripts/record_android_live_mic_receipt.sh',
      'platform:workflow-smoke': './scripts/run_hermes_platform_workflow.sh',
      'linux:release-build': './scripts/run_linux_release_build.sh',
    };

    for (final entry in expectedScripts.entries) {
      expect(scripts[entry.key], entry.value, reason: entry.key);
      final helperPath = entry.value.replaceFirst('./', '');
      final helper = File(helperPath);
      expect(helper.existsSync(), isTrue, reason: helperPath);
      expect(
        helper.readAsStringSync(),
        startsWith('#!/usr/bin/env bash\nset -euo pipefail'),
        reason: '$helperPath should fail closed as a bash helper',
      );
      expect(
        helper.statSync().mode & 0x49,
        isNonZero,
        reason: '$helperPath should be executable by at least one class',
      );
    }

    final androidVoiceSmoke = File(
      'scripts/run_android_voice_smoke.sh',
    ).readAsStringSync();
    final androidLoopSmoke = File(
      'scripts/run_android_hermes_voice_loop_smoke.sh',
    ).readAsStringSync();
    final androidDurableKeySmoke = File(
      'scripts/run_android_durable_key_smoke.sh',
    ).readAsStringSync();
    final androidLiveMicPrep = File(
      'scripts/prepare_android_live_mic_smoke.sh',
    ).readAsStringSync();
    final androidLiveMicReceipt = File(
      'scripts/record_android_live_mic_receipt.sh',
    ).readAsStringSync();
    final serverAudioReceipt = File(
      'scripts/record_hermes_server_audio_receipt.sh',
    ).readAsStringSync();
    for (final helperText in [
      androidVoiceSmoke,
      androidLoopSmoke,
      androidDurableKeySmoke,
      androidLiveMicPrep,
      androidLiveMicReceipt,
      serverAudioReceipt,
    ]) {
      expect(helperText, contains('not whole-goal completion evidence'));
      expect(
        helperText,
        contains('WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
      );
    }
    expect(androidVoiceSmoke, contains('Manual continuous-voice closeout'));
    expect(androidLoopSmoke, contains('not physical microphone\naudio input'));
    expect(androidLoopSmoke, contains('provider-backed replies'));
    expect(
      androidDurableKeySmoke,
      contains('not part of active pure-Hermes readiness'),
    );
    expect(
      androidDurableKeySmoke,
      contains(
        'does not prove\nHermes chat, voice, provider, platform, or realtime/server-audio readiness',
      ),
    );
    expect(
      androidLiveMicPrep,
      contains('does not\nprove physical microphone capture'),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_PHYSICAL_DEVICE_OBSERVED=true'),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_PHYSICAL_MIC_OBSERVED=true'),
    );
    expect(androidLiveMicReceipt, contains('physical_device_observed'));
    expect(androidLiveMicReceipt, contains('physical_mic_observed'));
    expect(androidLiveMicReceipt, contains('WING_ANDROID_TTS_OBSERVED=true'));
    expect(androidLiveMicReceipt, contains('WING_ANDROID_REARM_OBSERVED=true'));
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_NO_SECRET_LEAKS=true'),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_SYNTHETIC_AUDIO_USED=false'),
    );
    expect(androidLiveMicReceipt, contains('synthetic_audio_used'));
    expect(androidLiveMicReceipt, contains('android_target_type'));
    expect(androidLiveMicReceipt, contains('physical_device'));
    expect(androidLiveMicReceipt, contains('is_emulator'));
    expect(androidLiveMicReceipt, contains('audio_input_path'));
    expect(androidLiveMicReceipt, contains('physical_android_microphone'));
    expect(androidLiveMicReceipt, contains('local_device_stt_to_hermes_text'));
    expect(
      androidLiveMicReceipt,
      contains('provider_backed_hermes_text_reply'),
    );
    expect(androidLiveMicReceipt, contains('tts_observed_before_rearm'));
    expect(
      androidLiveMicReceipt,
      contains('must contain a short observed non-sensitive excerpt'),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_SECOND_SPOKEN_PHRASE must be a different'),
    );
    expect(
      androidLiveMicReceipt,
      contains(
        'WING_ANDROID_PROVIDER_REPLY must be an observed assistant reply excerpt',
      ),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_HERMES_URL must be a valid http(s) Hermes origin'),
    );
    expect(androidLiveMicReceipt, contains('distinct_rearmed_turn_observed'));
    expect(androidLiveMicReceipt, contains('hermes_url_sanitized'));
    expect(androidLiveMicReceipt, contains('head_sha'));
    expect(androidLiveMicReceipt, contains('git'));
    expect(androidLiveMicReceipt, contains('rev-parse'));
    expect(androidLiveMicReceipt, contains('device_properties'));
    expect(androidLiveMicReceipt, contains('package_info'));
    expect(androidLiveMicReceipt, contains('pm_path_output'));
    expect(androidLiveMicReceipt, contains('dumpsys'));
    expect(androidLiveMicReceipt, contains('versionName'));
    expect(androidLiveMicReceipt, contains('versionCode'));
    expect(androidLiveMicReceipt, contains('record_audio_granted'));
    expect(
      androidLiveMicReceipt,
      contains(r'android\.permission\.RECORD_AUDIO'),
    );
    expect(androidLiveMicReceipt, contains('ro.product.model'));
    expect(androidLiveMicReceipt, contains('ro.build.fingerprint'));
    expect(androidLiveMicReceipt, contains('urlsplit'));
    expect(androidLiveMicReceipt, contains("rsplit('@', 1)[-1]"));
    expect(
      androidLiveMicReceipt,
      contains("urlunsplit((parts.scheme, netloc, '', '', ''))"),
    );
    expect(androidLiveMicReceipt, contains('SECRET_PATTERN'));
    expect(androidLiveMicReceipt, contains('basic\\s+\\S+'));
    expect(androidLiveMicReceipt, contains('cookie|set-cookie'));
    expect(androidLiveMicReceipt, contains('://[^/\\s@]+@'));
    expect(androidLiveMicReceipt, contains('gh[pousr]_'));
    expect(androidLiveMicReceipt, contains('xox[abprs]-'));
    expect(androidLiveMicReceipt, contains('eyJ[a-z0-9_-]'));
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_TRANSPORT_OBSERVED=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY_OBSERVED=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_PLAYBACK_OBSERVED=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_ROUND_TRIP_OBSERVED=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_NO_SECRET_LEAKS=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_DEVICE_STT_USED=false'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_LOCAL_TTS_ONLY=false'),
    );
    expect(serverAudioReceipt, contains('device_stt_used'));
    expect(serverAudioReceipt, contains('local_tts_only'));
    expect(serverAudioReceipt, contains('hermes_server_audio_smoke'));
    expect(serverAudioReceipt, contains('hermes_realtime_or_audio_api'));
    expect(serverAudioReceipt, contains('client_audio_to_hermes_server_audio'));
    expect(
      serverAudioReceipt,
      contains('hermes_server_audio_to_client_playback'),
    );
    expect(serverAudioReceipt, contains('provider_reply_observed'));
    expect(serverAudioReceipt, contains('server_audio_playback_observed'));
    expect(serverAudioReceipt, contains('round_trip_observed'));
    expect(
      serverAudioReceipt,
      contains('short non-sensitive observed excerpt'),
    );
    expect(
      serverAudioReceipt,
      contains('PROVIDER_REPLY must differ from the prompt excerpt'),
    );
    expect(serverAudioReceipt, contains('not Android physical-mic'));
    expect(serverAudioReceipt, contains('whole-goal completion evidence'));
    expect(androidLiveMicReceipt, contains('len(value) > 240'));
    expect(androidLiveMicReceipt, contains('short non-sensitive excerpt'));
    expect(androidLiveMicReceipt, contains('record a non-sensitive excerpt'));
    expect(androidLiveMicReceipt, contains('whole-goal completion'));

    final liveSmoke = File(
      'scripts/run_live_hermes_smoke.sh',
    ).readAsStringSync();
    expect(liveSmoke, contains('API connect/session rendering only'));
    expect(liveSmoke, contains('not provider/model evidence'));
    expect(liveSmoke, contains('not a chat/voice provider smoke'));
    expect(liveSmoke, contains('not physical microphone evidence'));
    expect(liveSmoke, contains('not whole-goal completion evidence'));
    expect(
      liveSmoke,
      contains('WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
    );

    final providerSmoke = File(
      'scripts/run_provider_hermes_smoke.sh',
    ).readAsStringSync();
    expect(
      providerSmoke,
      contains('deterministic transcript voice only'),
      reason: 'provider smoke must not be mistaken for physical mic evidence',
    );
    expect(providerSmoke, contains('not physical microphone evidence'));
    expect(providerSmoke, contains('provider-backed Hermes typed text turn'));
    expect(providerSmoke, contains('deterministic transcript voice turn'));
    expect(providerSmoke, contains('safe_receipt_base_url'));
    expect(providerSmoke, contains('urlsplit'));
    expect(
      providerSmoke,
      contains("urlunsplit((parts.scheme, host, '', '', ''))"),
    );
    expect(providerSmoke, contains('head_sha'));
    expect(providerSmoke, contains('git rev-parse HEAD'));
    expect(providerSmoke, contains('platform workflow publication'));
    expect(providerSmoke, contains('deferred Hermes Desktop parity surfaces'));
    expect(
      providerSmoke,
      contains('does not prove Hermes realtime/server audio'),
    );
    expect(providerSmoke, contains('not whole-goal completion evidence'));
    expect(
      providerSmoke,
      contains('WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
    );
  });

  test('wing-cli keeps token output explicit', () async {
    const token = 'test-superuser-token';
    final environment = {
      ...Platform.environment,
      'WING_HERMES_URL': 'https://hermes.example',
      'WING_HERMES_TOKEN': token,
    };

    final info = await Process.run('./wing-cli', [
      'info',
    ], environment: environment);
    expect(info.exitCode, 0);
    expect(info.stdout, contains('https://hermes.example'));
    expect(info.stdout, isNot(contains(token)));

    final reveal = await Process.run('./wing-cli', [
      'token',
    ], environment: environment);
    expect(reveal.exitCode, 0);
    expect((reveal.stdout as String).trim(), token);
  });

  test('wing-cli creates a pairing link without exposing the token', () async {
    const token = 'test-superuser-token';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final origin = 'http://${server.address.address}:${server.port}';
    final requestHandled = server.first.then((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/v1/operator/enrollments');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer $token',
      );
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      expect(body['label'], 'test-phone');
      expect(body['origin'], origin);

      request.response
        ..statusCode = HttpStatus.created
        ..write(
          jsonEncode({
            'pairing_uri':
                'navivox://connect?origin=${Uri.encodeQueryComponent(origin)}&code=one-time',
          }),
        );
      await request.response.close();
    });

    final link = await Process.run(
      './wing-cli',
      ['link', '--origin', origin, '--label', 'test-phone'],
      environment: {...Platform.environment, 'WING_HERMES_TOKEN': token},
    );
    await requestHandled;

    expect(link.exitCode, 0, reason: link.stderr as String);
    final pairing = Uri.parse((link.stdout as String).trim());
    expect(pairing.scheme, 'wing');
    expect(pairing.host, 'connect');
    expect(pairing.queryParameters['origin'], origin);
    expect(pairing.queryParameters['code'], 'one-time');
    expect(link.stdout, isNot(contains(token)));
  });

  test('wing-cli explains when Hermes lacks secure enrollment', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final origin = 'http://${server.address.address}:${server.port}';
    final requestHandled = server.first.then((request) async {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });

    final qr = await Process.run(
      './wing-cli',
      ['qr', '--origin', origin],
      environment: {
        ...Platform.environment,
        'WING_HERMES_TOKEN': 'test-superuser-token',
      },
    );
    await requestHandled;

    expect(qr.exitCode, isNot(0));
    expect(qr.stderr, contains('does not support secure Wing enrollment'));
    expect(qr.stderr, contains('never placed in QR codes'));
  });

  test('wing-cli renders QR without an external package', () async {
    const token = 'test-superuser-token';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final origin = 'http://${server.address.address}:${server.port}';
    final requestHandled = server.first.then((request) async {
      request.response
        ..statusCode = HttpStatus.created
        ..write(
          jsonEncode({
            'pairing_uri':
                'navivox://connect?origin=${Uri.encodeQueryComponent(origin)}&code=one-time',
          }),
        );
      await request.response.close();
    });

    final qr = await Process.run(
      './wing-cli',
      ['qr', '--origin', origin],
      environment: {...Platform.environment, 'WING_HERMES_TOKEN': token},
    );
    await requestHandled;

    expect(qr.exitCode, 0, reason: qr.stderr as String);
    expect(qr.stdout, contains('\x1b[40m'));
    expect(qr.stdout, contains('\x1b[47m'));
    expect(qr.stdout, isNot(contains(token)));
  });

  test('wing-cli installer creates a runnable global command', () async {
    final installDir = await Directory.systemTemp.createTemp(
      'wing-cli-install-',
    );
    addTearDown(() => installDir.delete(recursive: true));

    final install = await Process.run('./install-wing-cli.sh', [
      '--prefix',
      installDir.path,
    ]);
    expect(install.exitCode, 0, reason: install.stderr as String);

    final installed = File('${installDir.path}/wing-cli');
    expect(installed.existsSync(), isTrue);
    expect(installed.statSync().mode & 0x49, isNonZero);
    expect(
      File('${installDir.path}/.wing-cli/qrcodegen.py').existsSync(),
      isTrue,
    );

    final help = await Process.run(installed.path, ['--help']);
    expect(help.exitCode, 0);
    expect(help.stdout, contains('Usage: ./wing-cli'));
  });
}
