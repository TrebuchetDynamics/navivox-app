import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/app.dart';
import 'package:navivox/theme/navivox_theme.dart';

void main() {
  test('Navivox themes provide light and dark Telegram-blue palettes', () {
    expect(navivoxTelegramBlue, const Color(0xff229ed9));
    expect(navivoxLightTheme.useMaterial3, isTrue);
    expect(navivoxDarkTheme.useMaterial3, isTrue);
    expect(navivoxLightTheme.colorScheme.brightness, Brightness.light);
    expect(navivoxDarkTheme.colorScheme.brightness, Brightness.dark);
    expect(navivoxLightTheme.appBarTheme.centerTitle, isFalse);
    expect(navivoxDarkTheme.appBarTheme.centerTitle, isFalse);
  });

  testWidgets('NavivoxApp exposes system light and dark themes', (
    tester,
  ) async {
    await tester.pumpWidget(const NavivoxApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.colorScheme.brightness, Brightness.light);
    expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
  });
}
