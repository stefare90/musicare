import 'package:flutter/material.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/core/theme/app_colors.dart';
import 'package:music_are/core/theme/app_typography.dart';

abstract class AppTheme {
  static ThemeData get darkTheme => darkThemeOf(AppAccent.violet);
  static ThemeData get lightTheme => lightThemeOf(AppAccent.violet);

  static ThemeData darkThemeOf(AppAccent accent, {bool amoled = true}) =>
      _themeFrom(
        brightness: Brightness.dark,
        primary: accent.color,
        palette: amoled ? AppColors.amoled : AppColors.dark,
      );

  static ThemeData lightThemeOf(AppAccent accent) => _themeFrom(
    brightness: Brightness.light,
    primary: _readableOnLight(accent.color),
    palette: AppColors.light,
  );

  static ThemeData _themeFrom({
    required Brightness brightness,
    required Color primary,
    required AppSurfacePalette palette,
  }) {
    final base = brightness == Brightness.dark
        ? const ColorScheme.dark()
        : const ColorScheme.light();
    final lighter = _lighter(primary);
    final onLighter = _onColor(lighter);
    final colorScheme = base.copyWith(
      primary: primary,
      onPrimary: _onColor(primary),
      primaryContainer: primary,
      onPrimaryContainer: _onColor(primary),
      secondary: lighter,
      onSecondary: onLighter,
      secondaryContainer: Color.lerp(palette.surface, primary, 0.35),
      onSecondaryContainer: palette.textPrimary,
      tertiary: lighter,
      onTertiary: onLighter,
      tertiaryContainer: Color.lerp(palette.surface, primary, 0.25),
      onTertiaryContainer: palette.textPrimary,
      surface: palette.surface,
      surfaceContainerLow: palette.surfaceContainerLow,
      surfaceContainer: palette.surfaceContainer,
      surfaceContainerHigh: palette.surfaceContainerHigh,
      surfaceContainerHighest: palette.surfaceContainerHighest,
      onSurfaceVariant: palette.textSecondary,
      outlineVariant: palette.outlineVariant,
      error: AppColors.error,
      onError: AppColors.onError,
      onSurface: palette.textPrimary,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      backgroundColor: palette.background,
      cardColor: palette.surfaceCard,
      highlightColor: palette.surfaceHighlight,
    );
  }

  static Color _onColor(Color color) =>
      color.computeLuminance() > 0.179 ? Colors.black : Colors.white;

  static Color _readableOnLight(Color color) {
    var hsl = HSLColor.fromColor(color);
    var result = color;
    while (result.computeLuminance() > 0.15 && hsl.lightness > 0.05) {
      hsl = hsl.withLightness(hsl.lightness - 0.02);
      result = hsl.toColor();
    }
    return result;
  }

  static Color _lighter(Color color) =>
      Color.lerp(color, Colors.white, 0.4) ?? color;

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color backgroundColor,
    required Color cardColor,
    required Color highlightColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: AppTypography.textTheme(colorScheme.onSurface),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: highlightColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
