import 'package:flutter/material.dart';
import 'package:music_are/core/theme/app_colors.dart';
import 'package:music_are/core/theme/app_typography.dart';

abstract class AppTheme {
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primaryVariant,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onError: AppColors.onError,
      onPrimary: Colors.black,
      onSurface: AppColors.darkTextPrimary,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      backgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurfaceCard,
      highlightColor: AppColors.darkSurfaceHighlight,
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryVariant,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onError: AppColors.onError,
      onPrimary: Colors.white,
      onSurface: AppColors.lightTextPrimary,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      backgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurfaceCard,
      highlightColor: AppColors.lightSurfaceHighlight,
    );
  }

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
