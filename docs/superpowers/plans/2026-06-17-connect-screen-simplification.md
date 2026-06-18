# Connect Screen Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the setup/connect screen so QR import is the primary action and manual entry lives inside a collapsed expansion tile, removing the address+port split and the "Copy fix instructions" button from the main card.

**Architecture:** The presentation layer (`setup_screen_presentation.dart`) drops address/port labels and adds a single URL field label + "Enter manually" label. The widget (`setup_screen.dart`) replaces two controllers with one `_urlController`, adds an `ExpansionTileController` for auto-expand on import, and restructures the card layout: full-width QR button first, then `ExpansionTile` with the manual form inside.

**Tech Stack:** Flutter, Riverpod, `ExpansionTileController` (Flutter built-in)

---

## File Map

| File | Change |
|---|---|
| `lib/features/servers/setup/presentation/screen/setup_screen_presentation.dart` | Remove address/port/fixInstructions labels; add url/enterManually labels; shorten pairingInstructions; update manual readiness message |
| `lib/features/servers/screens/setup_screen.dart` | Replace two address/port controllers with one URL controller; add ExpansionTileController; restructure build layout; update submit/import logic |
| `test/features/servers/setup/presentation/setup_screen_presentation_test.dart` | Update assertions for removed/changed labels and copy |
| `test/features/servers/setup/shared/setup_screen_test_contracts.dart` | Replace address/port helpers with URL helpers; add expandManualEntry |
| `test/features/servers/setup/widgets/setup_token_visibility_test.dart` | Expand tile before interacting; update button finder type |
| `test/features/servers/setup/widgets/setup_qr_image_import_test.dart` | Check URL field instead of address+port; assert expansion auto-opens |
| `test/features/servers/setup/flows/navivox_connect_and_talk_test.dart` | Replace address/port calls with URL field; expand tile where needed; update accessibility test; fix copy-fix-instructions test |

---

## Task 1: Update presentation labels and copy

**Files:**
- Modify: `lib/features/servers/setup/presentation/screen/setup_screen_presentation.dart`

- [ ] **Step 1: Remove address/port/fixInstructions properties and add URL/enterManually properties**

Replace the block from `pairingInstructions` through `fixInstructionsButtonLabel` with:

```dart
  String get pairingInstructions =>
      'Run `gormes navivox pair`, then scan the QR or open the pairing link.';

  String get urlFieldLabel => 'Gateway URL';

  String get urlFieldSemanticLabel => 'Gateway URL field';

  String get urlFieldSemanticHint =>
      'Enter the Gormes gateway URL, for example http://127.0.0.1:8765.';

  String get tokenFieldLabel => 'Pairing token';

  String get tokenFieldSemanticLabel => 'Pairing token field';

  String get tokenFieldSemanticHint =>
      'Enter the pairing token printed by Gormes.';

  String get enterManuallyLabel => 'Enter manually';

  String get importQrButtonLabel => 'Import QR image';
```

Delete these properties entirely (they are unused after this task):
- `networkHint` — keep (still used by `_SetupHelpCard`)
- `addressFieldLabel`, `addressFieldSemanticLabel`, `addressFieldSemanticHint` — **delete**
- `portFieldLabel`, `portFieldSemanticLabel`, `portFieldSemanticHint` — **delete**
- `fixInstructionsButtonLabel` — **delete**

- [ ] **Step 2: Update manual readiness message**

In `pairingReadiness`, change the `manual` branch message:

```dart
    return const SetupPairingReadinessPresentation(
      status: SetupPairingReadinessStatus.manual,
      statusLabel: 'Ready for pairing details',
      message:
          'Use a Gormes pairing link, or tap Enter manually below to type the gateway URL and token.',
    );
```

---

## Task 2: Update presentation unit tests

**Files:**
- Modify: `test/features/servers/setup/presentation/setup_screen_presentation_test.dart`

- [ ] **Step 1: Run tests to confirm current failures**

```bash
cd /home/xel/git/gormes/navivox-app
flutter test test/features/servers/setup/presentation/setup_screen_presentation_test.dart --concurrency=1
```

Expected: failures on `addressFieldLabel`, `portFieldLabel`, `fixInstructionsButtonLabel`, `pairingInstructions` contains `connect-info`, etc.

- [ ] **Step 2: Update the first test block**

Replace the `'centralizes first-run setup field and action copy'` test body with:

```dart
  test('centralizes first-run setup field and action copy', () {
    expect(presentation.title, 'Connect to Gormes');
    expect(presentation.pairingInstructions, contains('gormes navivox pair'));
    expect(presentation.pairingInstructions, contains('scan the QR'));
    expect(presentation.pairingInstructions, contains('open the pairing link'));
    expect(presentation.networkHint, contains('10.0.2.2'));
    expect(presentation.urlFieldLabel, 'Gateway URL');
    expect(presentation.urlFieldSemanticLabel, 'Gateway URL field');
    expect(presentation.urlFieldSemanticHint, contains('127.0.0.1:8765'));
    expect(presentation.enterManuallyLabel, 'Enter manually');
    expect(presentation.tokenFieldLabel, 'Pairing token');
    expect(presentation.tokenFieldSemanticLabel, 'Pairing token field');
    expect(presentation.tokenFieldSemanticHint, contains('printed by Gormes'));
    expect(presentation.importQrButtonLabel, 'Import QR image');
    expect(presentation.connectButtonLabel, 'Connect and talk');
    expect(presentation.connectButtonSemanticHint, contains('open chat'));
    expect(
      presentation
          .pairingReadiness(
            connecting: false,
            connectedSession: false,
            source: PairingHandoffSource.manual,
            hasError: false,
          )
          .title,
      'Pairing readiness',
    );
  });
```

- [ ] **Step 3: Update the manual readiness message assertion**

In the `'summarizes setup Pairing readiness states'` test, find:

```dart
    expect(manual.message, contains('enter gateway address'));
```

Replace with:

```dart
    expect(manual.message, contains('Enter manually'));
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/features/servers/setup/presentation/setup_screen_presentation_test.dart --concurrency=1
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/servers/setup/presentation/screen/setup_screen_presentation.dart \
        test/features/servers/setup/presentation/setup_screen_presentation_test.dart
git commit -m "feat(setup): update presentation labels for URL field and simplified copy"
```

---

## Task 3: Update shared test contracts

**Files:**
- Modify: `test/features/servers/setup/shared/setup_screen_test_contracts.dart`

- [ ] **Step 1: Replace address/port helpers with URL helpers and add expandManualEntry**

Replace the entire file content with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const setupUrlLabel = 'Gateway URL';
const setupTokenLabel = 'Pairing token';
const setupConnectLabel = 'Connect and talk';
const setupImportQrLabel = 'Import QR image';
const setupEnterManuallyLabel = 'Enter manually';
const setupTokenVisibilityButtonKey = ValueKey('setup-token-visibility-button');

Finder setupUrlField() => find.widgetWithText(TextField, setupUrlLabel);
Finder setupTokenField() => find.widgetWithText(TextField, setupTokenLabel);
Finder setupConnectAction() => find.text(setupConnectLabel);
Finder setupImportQrAction() => find.bySemanticsLabel(setupImportQrLabel);
Finder setupTokenVisibilityButton() =>
    find.byKey(setupTokenVisibilityButtonKey);

/// Expands the "Enter manually" expansion tile so URL/token fields are visible.
Future<void> expandManualEntry(WidgetTester tester) async {
  await tester.tap(find.text(setupEnterManuallyLabel));
  await tester.pumpAndSettle();
}

Future<void> enterSetupUrl(WidgetTester tester, String url) async {
  await tester.enterText(setupUrlField(), url);
}

Future<void> enterSetupToken(WidgetTester tester, String token) async {
  await tester.enterText(setupTokenField(), token);
}

Future<void> tapSetupConnect(WidgetTester tester) async {
  await tester.ensureVisible(setupConnectAction());
  await tester.tap(setupConnectAction());
}

TextField setupUrlTextField(WidgetTester tester) {
  return tester.widget<TextField>(setupUrlField());
}

TextField setupTokenTextField(WidgetTester tester) {
  return tester.widget<TextField>(setupTokenField());
}

class ClipboardCapture {
  final copiedTexts = <String>[];

  void install(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedTexts.add(
            (call.arguments as Map<Object?, Object?>)['text']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}
```

---

## Task 4: Update token visibility widget test

**Files:**
- Modify: `test/features/servers/setup/widgets/setup_token_visibility_test.dart`

- [ ] **Step 1: Expand tile before interacting; update button type**

Replace the entire file with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';

import '../../../shared/app/test_material_app.dart';
import '../shared/setup_screen_test_contracts.dart';

void main() {
  testWidgets('pairing token can be shown and hidden without losing text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TestProviderMaterialApp(home: SetupScreen()));

    // Expand the manual entry section so the token field is visible.
    await expandManualEntry(tester);

    final tokenFieldFinder = setupTokenField();
    TextField tokenField() => setupTokenTextField(tester);

    expect(tokenField().obscureText, isTrue);
    expect(setupTokenVisibilityButton(), findsOneWidget);

    await tester.enterText(tokenFieldFinder, 'nvbx_visible_when_requested');
    final button = tester.widget<IconButton>(setupTokenVisibilityButton());
    button.onPressed!();
    await tester.pump();

    expect(tokenField().obscureText, isFalse);
    expect(setupTokenVisibilityButton(), findsOneWidget);
    expect(tokenField().controller?.text, 'nvbx_visible_when_requested');

    final button2 = tester.widget<IconButton>(setupTokenVisibilityButton());
    button2.onPressed!();
    await tester.pump();

    expect(tokenField().obscureText, isTrue);
    expect(setupTokenVisibilityButton(), findsOneWidget);
    expect(tokenField().controller?.text, 'nvbx_visible_when_requested');
  });
}
```

---

## Task 5: Update QR import widget test

**Files:**
- Modify: `test/features/servers/setup/widgets/setup_qr_image_import_test.dart`

- [ ] **Step 1: Update the widget test to check URL field and auto-expand**

Find the first `testWidgets` block (`'QR image import fills setup fields without rendering the token'`) and replace it with:

```dart
  testWidgets(
    'QR image import fills setup fields and auto-expands manual entry',
    (tester) async {
      await tester.pumpWidget(
        TestProviderMaterialApp(
          home: SetupScreen(
            qrImageImporter: () async => const SetupQrImageImport(
              baseUrl: 'http://10.0.2.2:8765',
              token: 'nvbx_from_qr_picture',
            ),
          ),
        ),
      );

      final importButton = setupImportQrAction();
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      // Auto-expand should have opened the manual entry section.
      final urlField = setupUrlTextField(tester);
      final tokenField = setupTokenTextField(tester);

      expect(urlField.controller?.text, 'http://10.0.2.2:8765');
      expect(tokenField.controller?.text, 'nvbx_from_qr_picture');
      expect(tokenField.obscureText, isTrue);
      expect(find.text('Imported QR connection details.'), findsOneWidget);
      expect(visibleTextContaining('nvbx_from_qr_picture'), findsNothing);
    },
  );
```

---

## Task 6: Update flow tests

**Files:**
- Modify: `test/features/servers/setup/flows/navivox_connect_and_talk_test.dart`

- [ ] **Step 1: Update imports — remove unused address/port contract imports if any**

No import changes needed; the contracts file is imported wholesale.

- [ ] **Step 2: Update the accessibility test (around line 61)**

Replace the accessibility test body. Find:

```dart
      expect(find.bySemanticsLabel('Gateway address field'), findsOneWidget);
      expect(find.bySemanticsLabel('Gateway port field'), findsOneWidget);
      expect(find.bySemanticsLabel('Pairing token field'), findsOneWidget);
      expect(find.bySemanticsLabel('Import QR image'), findsOneWidget);
      expect(find.bySemanticsLabel('Copy fix instructions'), findsOneWidget);
      expect(find.bySemanticsLabel('Show pairing token'), findsOneWidget);
      expect(find.bySemanticsLabel('Connect and talk'), findsOneWidget);
```

Replace with:

```dart
      // Primary control always visible.
      expect(find.bySemanticsLabel('Import QR image'), findsOneWidget);

      // Expand manual entry to check its accessibility labels.
      await expandManualEntry(tester);

      expect(find.bySemanticsLabel('Gateway URL field'), findsOneWidget);
      expect(find.bySemanticsLabel('Pairing token field'), findsOneWidget);
      expect(find.bySemanticsLabel('Show pairing token'), findsOneWidget);
      expect(find.bySemanticsLabel('Connect and talk'), findsOneWidget);
```

- [ ] **Step 3: Update "pressing done in the token field connects" (around line 83)**

Find:

```dart
    await tester.enterText(setupAddressField(), 'http://127.0.0.1:8765');
    final tokenField = setupTokenField();
    await tester.enterText(tokenField, 'nvbx_test_token');
```

Replace with:

```dart
    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'http://127.0.0.1:8765');
    final tokenField = setupTokenField();
    await tester.enterText(tokenField, 'nvbx_test_token');
```

- [ ] **Step 4: Update "setup uses separate address and port fields" test (around line 102)**

Find and replace the whole test:

```dart
  testWidgets('setup uses separate address and port fields', (tester) async {
```

with:

```dart
  testWidgets('setup uses a single URL field for gateway address and port', (tester) async {
```

Find:

```dart
    await tester.enterText(setupAddressField(), '127.0.0.1');
    await tester.enterText(setupPortField(), '8765');
```

Replace with:

```dart
    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'http://127.0.0.1:8765');
```

- [ ] **Step 5: Update "setup detects a port pasted into the address field" test (around line 118)**

Find:

```dart
    await tester.enterText(setupAddressField(), 'http://127.0.0.1:7319');
    await tester.enterText(setupPortField(), '8765');
```

Replace with:

```dart
    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'http://127.0.0.1:7319');
```

- [ ] **Step 6: Update "setup trims connection details" test (around line 136)**

Find:

```dart
    await tester.enterText(setupAddressField(), '  http://127.0.0.1:8765  ');
```

Replace with:

```dart
    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), '  http://127.0.0.1:8765  ');
```

- [ ] **Step 7: Update connect-info test (line ~34) and any other setupAddressField() calls**

Find every remaining `setupAddressField()` and `setupPortField()` call. For each, add `await expandManualEntry(tester);` before the first URL entry, and replace:

- `await tester.enterText(setupAddressField(), '<url>');` → `await tester.enterText(setupUrlField(), '<url>');`
- `await tester.enterText(setupPortField(), '<port>');` → delete (port is now part of the URL)

Lines to update (based on earlier grep):
- Line 34: `setupAddressField()` → `setupUrlField()` with `expandManualEntry` before it
- Line 92: `setupAddressField()` → `setupUrlField()` with `expandManualEntry` before it
- Line 145 (trims test): already handled in step 6
- Line 418 (validates URL): expand + use `setupUrlField()`
- Line 560: `setupAddressField()` → `setupUrlField()` with `expandManualEntry` before it

- [ ] **Step 8: Update "setup validates the gateway URL" test (around line 409)**

Find:

```dart
    await tester.enterText(setupAddressField(), 'ftp://example.com');
```

Replace with:

```dart
    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'ftp://example.com');
```

Also find:

```dart
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
```

This is fine — `setupConnectAction()` finds `find.text('Connect and talk')` which is inside the now-expanded tile.

- [ ] **Step 9: Update "copy Navivox fix instructions" test (around line 510)**

The "Copy fix instructions" button now lives only in the help card. Add help card expansion before tapping it. Find:

```dart
      await tester.ensureVisible(find.text('Copy fix instructions').last);
      await tester.tap(find.text('Copy fix instructions').last);
```

Replace with:

```dart
      await tester.ensureVisible(find.text('Need setup help?'));
      await tester.tap(find.text('Need setup help?'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Copy fix instructions'));
      await tester.tap(find.text('Copy fix instructions'));
```

- [ ] **Step 10: Update "setup screen shows Termux bootstrap guidance" test (around line 428)**

Find:

```dart
    expect(find.text('Copy fix instructions'), findsWidgets);
```

Replace with:

```dart
    expect(find.text('Copy fix instructions'), findsOneWidget);
```

(Now only one instance: in the help card. The main card button is gone.)

- [ ] **Step 11: Run all setup flow tests**

```bash
flutter test test/features/servers/setup/flows/navivox_connect_and_talk_test.dart --concurrency=1
```

Expected: all pass (tests compile but widget implementation isn't changed yet, so they will fail on widget finders — that's expected until Task 7+8).

---

## Task 7: Restructure setup_screen.dart — state and methods

**Files:**
- Modify: `lib/features/servers/screens/setup_screen.dart`

- [ ] **Step 1: Replace controllers and add ExpansionTileController**

In `_SetupScreenState`, replace:

```dart
  final _addressController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8765');
  final _tokenController = TextEditingController();
  bool _connecting = false;
  bool _showToken = false;
  bool _importingQr = false;
  String _scheme = 'http';
  String? _webSocketUrl;
```

With:

```dart
  final _urlController = TextEditingController(text: 'http://127.0.0.1:8765');
  final _tokenController = TextEditingController();
  final _expansionController = ExpansionTileController();
  bool _connecting = false;
  bool _showToken = false;
  bool _importingQr = false;
  String? _webSocketUrl;
```

- [ ] **Step 2: Update dispose()**

Replace:

```dart
    _addressController.dispose();
    _portController.dispose();
    _tokenController.dispose();
```

With:

```dart
    _urlController.dispose();
    _tokenController.dispose();
```

- [ ] **Step 3: Replace _addressField() and _portField() with _urlField()**

Delete `_addressField()` and `_portField()`. Add:

```dart
  Widget _urlField() {
    return Semantics(
      label: _setupScreenPresentation.urlFieldSemanticLabel,
      hint: _setupScreenPresentation.urlFieldSemanticHint,
      textField: true,
      child: TextField(
        controller: _urlController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.dns_outlined),
          labelText: _setupScreenPresentation.urlFieldLabel,
        ),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.next,
        onChanged: _handleUrlChanged,
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
    );
  }
```

- [ ] **Step 4: Update _tokenField() to add suffix icon visibility toggle**

Replace the existing `_tokenField()` method with:

```dart
  Widget _tokenField() {
    return Semantics(
      label: _setupScreenPresentation.tokenFieldSemanticLabel,
      hint: _setupScreenPresentation.tokenFieldSemanticHint,
      textField: true,
      obscured: !_showToken,
      child: TextField(
        controller: _tokenController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.key_outlined),
          labelText: _setupScreenPresentation.tokenFieldLabel,
          suffixIcon: IconButton(
            key: const ValueKey('setup-token-visibility-button'),
            icon: Icon(
              _showToken ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip: _setupScreenPresentation.tokenVisibilityLabel(
              showToken: _showToken,
            ),
            onPressed: () => setState(() => _showToken = !_showToken),
          ),
        ),
        obscureText: !_showToken,
        textInputAction: TextInputAction.done,
        onSubmitted: _connecting ? null : (_) => _submitManualPairingHandoff(),
      ),
    );
  }
```

- [ ] **Step 5: Replace _handleAddressChanged and _handlePortChanged with _handleUrlChanged**

Delete `_handleAddressChanged` and `_handlePortChanged`. Add:

```dart
  void _handleUrlChanged(String _) {
    _webSocketUrl = null;
    _handoffFlow = _handoffFlow.applyManualConnectionEdit(
      PairingHandoffManualEdit.address,
    );
  }
```

- [ ] **Step 6: Update _safeHandoffHostSummary()**

Replace:

```dart
  String _safeHandoffHostSummary() {
    return _setupScreenPresentation.handoffHostSummary(
      scheme: _scheme,
      address: _addressController.text,
      port: _portController.text,
    );
  }
```

With:

```dart
  String _safeHandoffHostSummary() {
    const presentation = GatewayConnectionPresentation();
    final parsed = presentation.splitBaseUrl(_urlController.text);
    if (parsed.hasError || parsed.baseUrl == null) return 'the new gateway';
    return parsed.baseUrl!;
  }
```

- [ ] **Step 7: Update _submitManualPairingHandoff()**

Replace:

```dart
  Future<void> _submitManualPairingHandoff() {
    return _handlePairingIntent(
      PairingIntent.submitManualHandoff(
        baseUrl: _safeHandoffHostSummary(),
        token: _tokenController.text,
        webSocketUrl: _webSocketUrl,
      ),
    );
  }
```

With (unchanged — `_safeHandoffHostSummary()` now returns the canonical baseUrl directly):

```dart
  Future<void> _submitManualPairingHandoff() {
    return _handlePairingIntent(
      PairingIntent.submitManualHandoff(
        baseUrl: _safeHandoffHostSummary(),
        token: _tokenController.text,
        webSocketUrl: _webSocketUrl,
      ),
    );
  }
```

No change needed here — `_safeHandoffHostSummary()` now parses from `_urlController`.

- [ ] **Step 8: Update _connectGateway() to use validateBaseUrl and connectRequest**

Replace the validation and request-building block:

```dart
    final validationError = presentation.validateAddressAndPort(
      address: _addressController.text,
      port: _portController.text,
      scheme: _scheme,
    );
    if (validationError != null) {
      setState(() {
        _notice = _setupScreenPresentation.validationFailureNotice(
          validationError,
        );
      });
      return;
    }
    final request = presentation.connectRequestFromParts(
      address: _addressController.text,
      port: _portController.text,
      token: _tokenController.text,
      scheme: _scheme,
      webSocketUrl: _webSocketUrl,
    );
```

With:

```dart
    final urlText = _urlController.text.trim();
    final validationError = presentation.validateBaseUrl(urlText);
    if (validationError != null) {
      setState(() {
        _notice = _setupScreenPresentation.validationFailureNotice(
          validationError,
        );
      });
      return;
    }
    final request = presentation.connectRequest(
      baseUrl: urlText,
      token: _tokenController.text,
      webSocketUrl: _webSocketUrl,
    );
```

- [ ] **Step 9: Update _applyConnectionImport() to set URL field and auto-expand**

Replace:

```dart
  void _applyConnectionImport(
    SetupQrImageImport result,
    SetupScreenNotice notice,
  ) {
    setState(() {
      if (result.baseUrl != null) {
        const presentation = GatewayConnectionPresentation();
        final parsed = presentation.splitBaseUrl(result.baseUrl!);
        if (!parsed.hasError) {
          _scheme = Uri.tryParse(parsed.baseUrl!)?.scheme ?? 'http';
          _addressController.text = parsed.address!;
          _portController.text = parsed.port!;
        }
      }
      if (result.token != null) {
        _tokenController.text = result.token!;
      }
      _webSocketUrl = result.webSocketUrl;
      _handoffFlow = PairingHandoffFlow.fromImport(result);
      _notice = notice;
    });
  }
```

With:

```dart
  void _applyConnectionImport(
    SetupQrImageImport result,
    SetupScreenNotice notice,
  ) {
    setState(() {
      if (result.baseUrl != null) {
        _urlController.text = result.baseUrl!;
      }
      if (result.token != null) {
        _tokenController.text = result.token!;
      }
      _webSocketUrl = result.webSocketUrl;
      _handoffFlow = PairingHandoffFlow.fromImport(result);
      _notice = notice;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _expansionController.expand();
    });
  }
```

- [ ] **Step 10: Run flutter analyze to check compile errors**

```bash
flutter analyze lib/features/servers/screens/setup_screen.dart
```

Expected: no errors (layout still references old widgets — fix in Task 8).

---

## Task 8: Restructure setup_screen.dart — layout

**Files:**
- Modify: `lib/features/servers/screens/setup_screen.dart`

- [ ] **Step 1: Replace the card body in build()**

Find the `Card` widget that starts with `child: Padding(` containing `'Pair with Gormes'` title. Replace its entire body with:

```dart
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 16 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton.icon(
                                  key: const ValueKey(
                                    'setup-import-qr-button',
                                  ),
                                  onPressed:
                                      _connecting || _importingQr
                                          ? null
                                          : _importQrImage,
                                  icon: _importingQr
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.qr_code_scanner),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  label: Text(
                                    _setupScreenPresentation.importQrButtonLabel,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ExpansionTile(
                                  controller: _expansionController,
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                    _setupScreenPresentation.enterManuallyLabel,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                          color:
                                              colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  children: [
                                    const SizedBox(height: 8),
                                    _urlField(),
                                    const SizedBox(height: 12),
                                    _tokenField(),
                                    const SizedBox(height: 16),
                                    Semantics(
                                      container: true,
                                      label: _setupScreenPresentation
                                          .connectButtonLabel,
                                      hint: _setupScreenPresentation
                                          .connectButtonSemanticHint,
                                      button: true,
                                      enabled: !_connecting,
                                      onTap: _connecting
                                          ? null
                                          : _submitManualPairingHandoff,
                                      child: ExcludeSemantics(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(52),
                                            textStyle: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          onPressed: _connecting
                                              ? null
                                              : _submitManualPairingHandoff,
                                          icon: _connecting
                                              ? const SizedBox.square(
                                                  dimension: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(Icons.hub),
                                          label: Text(
                                            _setupScreenPresentation
                                                .connectButtonLabel,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                                if (_notice != null) ...[
                                  const SizedBox(height: 12),
                                  _SetupNoticeBanner(notice: _notice!),
                                ],
                              ],
                            ),
                          ),
                        ),
```

- [ ] **Step 2: Remove the old showReadiness variable if now unused**

Check if `showReadiness` is still used. The `PairingReadinessCard` should still appear when status is non-manual. Keep:

```dart
                        if (showReadiness) ...[
                          _PairingReadinessCard(readiness: readiness),
                          const SizedBox(height: 12),
                        ],
```

This is unchanged — still correct.

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/features/servers/screens/setup_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Run all setup tests**

```bash
flutter test test/features/servers/setup/ --concurrency=1
```

Expected: all pass.

- [ ] **Step 5: Run full test suite**

```bash
flutter test --concurrency=1
```

Expected: 927+ tests pass, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add lib/features/servers/screens/setup_screen.dart \
        test/features/servers/setup/shared/setup_screen_test_contracts.dart \
        test/features/servers/setup/widgets/setup_token_visibility_test.dart \
        test/features/servers/setup/widgets/setup_qr_image_import_test.dart \
        test/features/servers/setup/flows/navivox_connect_and_talk_test.dart
git commit -m "feat(setup): QR-first layout, single URL field, token visibility suffix icon"
```

---

## Self-Review

**Spec coverage:**
- ✅ Hero instructions shortened (Task 1)
- ✅ QR button full-width primary (Task 8)
- ✅ ExpansionTile "Enter manually" always starts closed (default behavior; no `initiallyExpanded: true`)
- ✅ Single URL field replacing address+port (Tasks 1, 7)
- ✅ Token visibility → suffix icon (Task 7)
- ✅ "Copy fix instructions" removed from main card (Task 8; stays in help card)
- ✅ Auto-expand on QR import (Task 7 step 9)
- ✅ `PairingReadinessCard` unchanged for non-manual states (Task 8 step 2)
- ✅ Help card unchanged (not touched)
- ✅ Tests updated for all changed contracts (Tasks 2–6)

**Type consistency check:**
- `_urlController` defined in Task 7 step 1, used in steps 3, 5, 6, 7, 8, 9 — consistent.
- `_expansionController` defined in Task 7 step 1, used in Task 7 step 9 and Task 8 step 1 — consistent.
- `urlFieldLabel`, `urlFieldSemanticLabel`, `urlFieldSemanticHint`, `enterManuallyLabel` defined in Task 1, asserted in Task 2, used in Task 7 — consistent.
- `setupUrlField()`, `expandManualEntry()` defined in Task 3, used in Tasks 4–6 — consistent.
