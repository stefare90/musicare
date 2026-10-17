import 'package:flutter/material.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_state.dart';

class ThemeCubit extends SafeCubit<ThemeState> {
  final PreferencesService _preferences;

  ThemeCubit(this._preferences)
    : super(
        ThemeState(
          themeMode: _preferences.getThemeMode() ?? ThemeMode.dark,
          accent: _preferences.getAccent() ?? AppAccent.violet,
          amoledBlack: _preferences.getAmoledBlack() ?? true,
          locale: _localeOf(_preferences.getLanguageCode()),
        ),
      );

  static Locale? _localeOf(String? languageCode) =>
      languageCode == null ? null : Locale(languageCode);

  void setThemeMode(ThemeMode mode) {
    if (mode == state.themeMode) return;
    emit(state.copyWith(themeMode: mode));
    _preferences.setThemeMode(mode);
  }

  void setAccent(AppAccent accent) {
    if (accent == state.accent) return;
    emit(state.copyWith(accent: accent));
    _preferences.setAccent(accent);
  }

  void setAmoledBlack(bool value) {
    if (value == state.amoledBlack) return;
    emit(state.copyWith(amoledBlack: value));
    _preferences.setAmoledBlack(value);
  }

  void setLocale(Locale locale) {
    if (locale.languageCode == state.locale?.languageCode) return;
    emit(state.copyWith(locale: locale));
    _preferences.setLanguageCode(locale.languageCode);
  }
}
