import 'package:flutter/material.dart';

const navivoxTelegramBlue = Color(0xff229ed9);

final navivoxLightTheme = _buildNavivoxTheme(Brightness.light);
final navivoxDarkTheme = _buildNavivoxTheme(Brightness.dark);

ThemeData _buildNavivoxTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: navivoxTelegramBlue,
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    listTileTheme: ListTileThemeData(
      selectedColor: colorScheme.primary,
      selectedTileColor: colorScheme.primary.withAlpha(24),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
      selectedLabelTextStyle: TextStyle(color: colorScheme.onSurface),
    ),
  );
}
