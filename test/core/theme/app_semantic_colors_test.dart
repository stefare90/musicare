import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/core/theme/app_semantic_colors.dart';
import 'package:music_are/core/theme/app_theme.dart';

void main() {
  test('every accent keeps a warning colour of its own', () {
    for (final accent in AppAccent.values) {
      for (final theme in [
        AppTheme.darkThemeOf(accent),
        AppTheme.lightThemeOf(accent),
      ]) {
        final semantic = theme.extension<AppSemanticColors>();
        expect(semantic, isNotNull, reason: '$accent');
        expect(
          semantic!.warning,
          isNot(theme.colorScheme.primary),
          reason: 'warning must not follow the accent ($accent)',
        );
        expect(
          semantic.warning,
          isNot(theme.colorScheme.error),
          reason: 'warning and error must stay distinguishable ($accent)',
        );
      }
    }
  });

  test('the warning colour is picked by brightness', () {
    final dark = AppSemanticColors.of(Brightness.dark);
    final light = AppSemanticColors.of(Brightness.light);

    expect(dark.warning, isNot(light.warning));
    expect(dark.warningContainer, isNot(light.warningContainer));
    expect(dark.copyWith(warning: light.warning).warning, light.warning);
  });
}
