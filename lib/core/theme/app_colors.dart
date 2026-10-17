import 'package:flutter/material.dart';

class AppSurfacePalette {
  final Color background;
  final Color surface;
  final Color surfaceCard;
  final Color surfaceHighlight;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color outlineVariant;
  final Color textPrimary;
  final Color textSecondary;

  const AppSurfacePalette({
    required this.background,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceHighlight,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outlineVariant,
    required this.textPrimary,
    required this.textSecondary,
  });
}

abstract class AppColors {
  static const Color primary = Color.fromARGB(255, 193, 128, 255);
  static const Color error = Color.fromARGB(255, 255, 113, 113);
  static const Color onError = Color.fromARGB(255, 255, 255, 255);

  static const AppSurfacePalette light = AppSurfacePalette(
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    surfaceCard: Color(0xFFF1F3F4),
    surfaceHighlight: Color(0xFFE8EAED),
    surfaceContainerLow: Color(0xFFF8F9FA),
    surfaceContainer: Color(0xFFF1F3F4),
    surfaceContainerHigh: Color(0xFFE8EAED),
    surfaceContainerHighest: Color(0xFFDDE1E6),
    outlineVariant: Color(0xFFC4C7C5),
    textPrimary: Color(0xFF1F1F1F),
    textSecondary: Color(0xFF5F6368),
  );

  static const AppSurfacePalette dark = AppSurfacePalette(
    background: Color(0xFF121212),
    surface: Color(0xFF181818),
    surfaceCard: Color(0xFF242424),
    surfaceHighlight: Color(0xFF2A2A2A),
    surfaceContainerLow: Color(0xFF1A1A1A),
    surfaceContainer: Color(0xFF1E1E1E),
    surfaceContainerHigh: Color(0xFF262626),
    surfaceContainerHighest: Color(0xFF303030),
    outlineVariant: Color(0xFF4A4A4A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
  );

  static const AppSurfacePalette amoled = AppSurfacePalette(
    background: Color(0xFF000000),
    surface: Color(0xFF000000),
    surfaceCard: Color(0xFF101010),
    surfaceHighlight: Color(0xFF101010),
    surfaceContainerLow: Color(0xFF101010),
    surfaceContainer: Color(0xFF101010),
    surfaceContainerHigh: Color(0xFF141414),
    surfaceContainerHighest: Color(0xFF080808),
    outlineVariant: Color(0xFF3A3A3A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
  );
}
