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
