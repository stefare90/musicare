import 'package:flutter/material.dart';
import 'package:music_are/core/theme/app_accent.dart';

class ThemeState {
  final ThemeMode themeMode;
  final AppAccent accent;
  final bool amoledBlack;
  final Locale? locale;

  const ThemeState({
    required this.themeMode,
    required this.accent,
    required this.amoledBlack,
    required this.locale,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppAccent? accent,
    bool? amoledBlack,
    Locale? locale,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      amoledBlack: amoledBlack ?? this.amoledBlack,
      locale: locale ?? this.locale,
    );
  }
}
