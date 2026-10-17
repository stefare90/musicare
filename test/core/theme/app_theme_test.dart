import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/core/theme/app_colors.dart';
import 'package:music_are/core/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('dark theme', () {
    for (final accent in AppAccent.values) {
      test('${accent.name}: text on primary stays readable', () {
        final scheme = AppTheme.darkThemeOf(accent);
        expect(
          _contrast(scheme.colorScheme.onPrimary, scheme.colorScheme.primary),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    test('amoled uses absolute black surfaces with one raised color', () {
      final theme = AppTheme.darkThemeOf(AppAccent.violet);

      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(theme.colorScheme.surface, const Color(0xFF000000));
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF000000));
      expect(theme.cardTheme.color, AppColors.amoled.surfaceCard);
      expect(
        theme.colorScheme.surfaceContainerLow,
        AppColors.amoled.surfaceContainerLow,
      );
      expect(
        theme.colorScheme.surfaceContainerHighest,
        AppColors.amoled.surfaceContainerHighest,
      );
      expect(
        theme.colorScheme.surfaceContainerHigh,
        AppColors.amoled.surfaceContainerHigh,
      );
      expect(
        AppColors.amoled.surfaceContainerHighest.computeLuminance(),
        lessThan(AppColors.amoled.surfaceContainerLow.computeLuminance()),
      );
    });

    test('standard dark keeps the previous surfaces', () {
      final theme = AppTheme.darkThemeOf(AppAccent.violet, amoled: false);

      expect(theme.scaffoldBackgroundColor, AppColors.dark.background);
      expect(theme.colorScheme.surface, AppColors.dark.surface);
      expect(theme.cardTheme.color, AppColors.dark.surfaceCard);
    });

    test('the legacy getter defaults to amoled violet', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        AppColors.amoled.background,
      );
      expect(AppTheme.darkTheme.colorScheme.primary, AppColors.primary);
    });

    test('cover placeholders contrast with the surface', () {
      final scheme = AppTheme.darkThemeOf(AppAccent.violet).colorScheme;

      expect(scheme.surfaceContainerHighest, isNot(scheme.surface));
      expect(scheme.surfaceContainerHighest.computeLuminance(), greaterThan(0));
      expect(scheme.surfaceContainerHighest.computeLuminance(), lessThan(0.03));
    });
  });

  group('light theme', () {
    test('cover placeholders contrast with the surface', () {
      final scheme = AppTheme.lightThemeOf(AppAccent.violet).colorScheme;

      expect(scheme.surfaceContainerHighest, isNot(scheme.surface));
    });

    for (final accent in AppAccent.values) {
      test('${accent.name}: primary and its text stay readable', () {
        final theme = AppTheme.lightThemeOf(accent);
        final scheme = theme.colorScheme;

        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.primary, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}
