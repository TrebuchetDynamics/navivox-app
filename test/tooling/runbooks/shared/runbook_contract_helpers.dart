import 'package:flutter_test/flutter_test.dart';

import '../../shared/file_contract_helpers.dart';

const androidDeviceAndSecretContractsRunbook =
    'docs/runbooks/shared/android-device-and-secret-contracts.md';
const pairingSecretHandlingRunbook =
    'docs/runbooks/shared/pairing-secret-handling.md';

String readRunbookContractWithPairingSecretPolicy(String runbookPath) {
  return readRequiredFiles([
    resolveRunbookFacade(runbookPath),
    pairingSecretHandlingRunbook,
  ]);
}

String readRunbookContractWithSharedPolicy(String runbookPath) {
  return readRequiredFiles([
    resolveRunbookFacade(runbookPath),
    pairingSecretHandlingRunbook,
    androidDeviceAndSecretContractsRunbook,
  ]);
}

String resolveRunbookFacade(String runbookPath) {
  final text = readRequiredFile(runbookPath);
  final movedLink = RegExp(r'Moved to \[.*?\]\((.*?)\)\.').firstMatch(text);
  if (movedLink == null) {
    return runbookPath;
  }

  final destination = movedLink.group(1)!;
  final directory = runbookPath.split('/')..removeLast();
  return [...directory, destination].join('/');
}

void expectRunbookContainsAll(String text, Iterable<String> snippets) {
  for (final snippet in snippets) {
    expect(text, contains(snippet));
  }
}

void expectRunbookOmitsAll(String text, Iterable<String> snippets) {
  for (final snippet in snippets) {
    expect(text, isNot(contains(snippet)));
  }
}

void expectRunbookHasNoSecretPlaceholders(String text) {
  expectNoSecretPlaceholders(text);
}
