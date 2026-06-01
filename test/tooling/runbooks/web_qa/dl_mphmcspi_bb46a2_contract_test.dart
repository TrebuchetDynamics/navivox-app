import 'package:flutter_test/flutter_test.dart';

import '../shared/runbook_contract_helpers.dart';

void main() {
  test('Web QA handoff keeps browser verification and pairing secret boundaries', () {
    final text = readRunbookContractWithPairingSecretPolicy(
      'docs/runbooks/web-qa/dl-mphmcspi-bb46a2.md',
    );

    expectRunbookContainsAll(text, [
      '# Web QA Handoff',
      'browser pairing',
      'setup recovery',
      'first chat turn flows',
      'Do not paste tokens',
      'screenshots',
      'UI and diagnostic copy',
      'must not echo the token value',
    ]);
    expectRunbookHasNoSecretPlaceholders(text);
  });
}
