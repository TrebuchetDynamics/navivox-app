import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/channel/gateway/codecs/gateway_tool_artifact_codec.dart';

void main() {
  group('navivoxToolArtifactsFromGatewayMetadata', () {
    test(
      'builds bounded synthetic metadata artifacts from safe entries only',
      () {
        final artifacts = navivoxToolArtifactsFromGatewayMetadata({
          'Authorization': 'Bearer secret-token',
          'auth': 'Bearer short-secret',
          'credential': 'session-secret',
          'aws_access_key_id': 'AKIA-secret',
          'private_key_pem': '-----BEGIN PRIVATE KEY-----',
          'safe_label': 'visible',
        }, toolCallId: 'tool-1');

        expect(artifacts, hasLength(1));
        final summary = artifacts.single.summary ?? '';
        expect(summary, 'safe_label: visible');
        expect(summary, isNot(contains('Bearer secret-token')));
        expect(summary, isNot(contains('Bearer short-secret')));
        expect(summary, isNot(contains('session-secret')));
        expect(summary, isNot(contains('AKIA-secret')));
        expect(summary, isNot(contains('PRIVATE KEY')));
      },
    );

    test('preserves structured artifact metadata when present', () {
      final artifacts = navivoxToolArtifactsFromGatewayMetadata({
        'artifacts': [
          {
            'id': 'browser-state',
            'kind': 'page',
            'title': 'Browser state',
            'summary': 'Dashboard title and safe URL',
            'ref': 'artifact://browser-state',
          },
        ],
      }, toolCallId: 'tool-1');

      expect(artifacts, hasLength(1));
      expect(artifacts.single.id, 'browser-state');
      expect(artifacts.single.kind, 'page');
      expect(artifacts.single.title, 'Browser state');
      expect(artifacts.single.summary, 'Dashboard title and safe URL');
      expect(artifacts.single.ref, 'artifact://browser-state');
    });
  });

  group('navivoxSafeGatewayToolMetadataSummary', () {
    test(
      'collapses compound values and falls back when all keys are sensitive',
      () {
        expect(
          navivoxSafeGatewayToolMetadataSummary({
            'rows': [1, 2, 3],
            'details': {'nested': true},
          }),
          'rows: [list]; details: [object]',
        );

        expect(
          navivoxSafeGatewayToolMetadataSummary({'token': 'secret'}),
          'Metadata unavailable',
        );
      },
    );
  });
}
