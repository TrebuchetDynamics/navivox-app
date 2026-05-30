import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';

import '../../shared/app/test_material_app.dart';

void main() {
  testWidgets('pairing token can be shown and hidden without losing text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const TestProviderMaterialApp(home: SetupScreen()),
    );

    final tokenFieldFinder = find.widgetWithText(TextField, 'Pairing token');
    TextField tokenField() => tester.widget<TextField>(tokenFieldFinder);

    expect(tokenField().obscureText, isTrue);
    expect(_tokenVisibilityButton('Show pairing token'), findsOneWidget);

    await tester.enterText(tokenFieldFinder, 'nvbx_visible_when_requested');
    _pressTokenVisibilityButton(tester);
    await tester.pump();

    expect(tokenField().obscureText, isFalse);
    expect(_tokenVisibilityButton('Hide pairing token'), findsOneWidget);
    expect(tokenField().controller?.text, 'nvbx_visible_when_requested');

    _pressTokenVisibilityButton(tester);
    await tester.pump();

    expect(tokenField().obscureText, isTrue);
    expect(_tokenVisibilityButton('Show pairing token'), findsOneWidget);
    expect(tokenField().controller?.text, 'nvbx_visible_when_requested');
  });
}

Finder _tokenVisibilityButton(String _) {
  return find.byKey(const ValueKey('setup-token-visibility-button'));
}

void _pressTokenVisibilityButton(WidgetTester tester) {
  final button = tester.widget<TextButton>(
    _tokenVisibilityButton('setup-token-visibility-button'),
  );
  button.onPressed!();
}
