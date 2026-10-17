import 'package:flutter/material.dart';
import 'package:music_are/core/theme/app_colors.dart';

/// Selectable primary tint. [color] is the vibrant tone used by the dark theme;
/// the light theme derives a darker, readable tone from it.
enum AppAccent {
  violet(AppColors.primary),
  blue(Color(0xFF82B1FF)),
  cyan(Color(0xFF4DD0E1)),
  teal(Color(0xFF4DB6AC)),
  green(Color(0xFF81C784)),
  amber(Color(0xFFFFD54F)),
  orange(Color(0xFFFFB74D)),
  pink(Color(0xFFF48FB1));

  const AppAccent(this.color);

  final Color color;
}
