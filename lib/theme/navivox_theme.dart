import 'package:flutter/material.dart';

const navivoxTelegramBlue = Color(0xff229ed9);
const _navivoxTelegramDarkBackground = Color(0xff17212b);
const _navivoxTelegramDarkContainer = Color(0xff202b36);
const _navivoxTelegramDarkContainerHigh = Color(0xff263544);
const _navivoxTelegramDarkOutline = Color(0xff2f3d4a);

final navivoxLightTheme = _buildNavivoxTheme(Brightness.light);
final navivoxDarkTheme = _buildNavivoxTheme(Brightness.dark);

ThemeData _buildNavivoxTheme(Brightness brightness) {
  final seededScheme = ColorScheme.fromSeed(
    seedColor: navivoxTelegramBlue,
    brightness: brightness,
  );
  final colorScheme = brightness == Brightness.dark
      ? seededScheme.copyWith(
          primary: navivoxTelegramBlue,
          surface: _navivoxTelegramDarkBackground,
          surfaceContainerLowest: _navivoxTelegramDarkBackground,
          surfaceContainerLow: _navivoxTelegramDarkContainer,
          surfaceContainer: _navivoxTelegramDarkContainer,
          surfaceContainerHigh: _navivoxTelegramDarkContainerHigh,
          surfaceContainerHighest: _navivoxTelegramDarkContainerHigh,
          outlineVariant: _navivoxTelegramDarkOutline,
        )
      : seededScheme;

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: const CircleBorder(),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withAlpha(
        brightness == Brightness.dark ? 48 : 96,
      ),
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(96)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      selectedColor: colorScheme.primary,
      selectedTileColor: colorScheme.primary.withAlpha(24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      horizontalTitleGap: 20,
      minLeadingWidth: 24,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primary.withAlpha(24),
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      selectedLabelTextStyle: TextStyle(color: colorScheme.primary),
    ),
  );
}
