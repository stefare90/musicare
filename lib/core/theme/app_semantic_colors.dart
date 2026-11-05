import 'package:flutter/material.dart';
import 'package:music_are/core/theme/app_colors.dart';

/// Colours that carry a meaning of their own, independent of [ColorScheme.primary]
/// (which the user picks: a green accent must not mean "everything is fine").
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.warning,
    required this.warningContainer,
  });

  final Color warning;
  final Color warningContainer;

  static AppSemanticColors of(Brightness brightness) =>
      brightness == Brightness.dark
      ? const AppSemanticColors(
          warning: AppColors.warningOnDark,
          warningContainer: AppColors.warningContainerOnDark,
        )
      : const AppSemanticColors(
          warning: AppColors.warningOnLight,
          warningContainer: AppColors.warningContainerOnLight,
        );

  @override
  AppSemanticColors copyWith({Color? warning, Color? warningContainer}) {
    return AppSemanticColors(
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
    );
  }
}
