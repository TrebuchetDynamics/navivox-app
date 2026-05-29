import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/session/durable_credential_key_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.trebuchetdynamics.navivox/durable_keys');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('derives stable key aliases without raw identities', () {
    final alias = DurableCredentialKeyAlias.forGatewayInstall(
      gatewayId: 'gateway-public-id',
      appInstallIdentity: 'navi-install-abc',
    );
    final same = DurableCredentialKeyAlias.forGatewayInstall(
      gatewayId: ' gateway-public-id ',
      appInstallIdentity: ' navi-install-abc ',
    );

    expect(alias.value, same.value);
    expect(alias.value, startsWith('navivox_durable_'));
    expect(alias.value, isNot(contains('gateway-public-id')));
    expect(alias.value, isNot(contains('navi-install-abc')));
  });

  test('availability returns false when native adapter is absent', () async {
    final store = MethodChannelDurableCredentialKeyStore(channel: channel);

    expect(await store.isAvailable(), isFalse);
  });

  test('creates ES256 key pair and returns public JWK only', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          expect(call.method, 'createEs256KeyPair');
          expect(call.arguments, {'alias': 'navivox_durable_test'});
          return {
            'kty': 'EC',
            'crv': 'P-256',
            'x': 'public-x',
            'y': 'public-y',
            'alg': 'ES256',
            'kid': 'kid-1',
          };
        });
    final store = MethodChannelDurableCredentialKeyStore(channel: channel);

    final jwk = await store.createEs256KeyPair(
      alias: const DurableCredentialKeyAlias.native('navivox_durable_test'),
    );

    expect(jwk.toJson(), {
      'kty': 'EC',
      'crv': 'P-256',
      'x': 'public-x',
      'y': 'public-y',
      'alg': 'ES256',
      'kid': 'kid-1',
    });
    expect(jwk.toJson().keys, isNot(contains('d')));
    expect(calls.single.method, 'createEs256KeyPair');
  });

  test('signs canonical bytes and deletes local key alias', () async {
    final signature = Uint8List.fromList([9, 8, 7]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'signEs256') {
            expect(call.arguments['alias'], 'navivox_durable_test');
            expect(
              call.arguments['canonicalPayload'],
              Uint8List.fromList([1, 2, 3]),
            );
            return signature;
          }
          if (call.method == 'deleteKey') {
            expect(call.arguments, {'alias': 'navivox_durable_test'});
            return null;
          }
          fail('Unexpected method ${call.method}');
        });
    final store = MethodChannelDurableCredentialKeyStore(channel: channel);
    const alias = DurableCredentialKeyAlias.native('navivox_durable_test');

    final result = await store.sign(
      alias: alias,
      canonicalPayload: Uint8List.fromList([1, 2, 3]),
    );
    await store.deleteKey(alias: alias);

    expect(result, signature);
    expect(calls.map((call) => call.method), ['signEs256', 'deleteKey']);
  });
}
