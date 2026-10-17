import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PreferencesService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = PreferencesService(prefs);
  });

  test('defaults to dark, violet, amoled on and system locale', () {
    final cubit = ThemeCubit(service);

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.accent, AppAccent.violet);
    expect(cubit.state.amoledBlack, isTrue);
    expect(cubit.state.locale, isNull);
  });

  test('restores persisted values', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'light',
      'accent_color': 'teal',
      'amoled_black': false,
      'language_code': 'en',
    });
    prefs = await SharedPreferences.getInstance();

    final cubit = ThemeCubit(PreferencesService(prefs));

    expect(cubit.state.themeMode, ThemeMode.light);
    expect(cubit.state.accent, AppAccent.teal);
    expect(cubit.state.amoledBlack, isFalse);
    expect(cubit.state.locale, const Locale('en'));
  });

  test('setters emit the new state and persist it', () async {
    final cubit = ThemeCubit(service);

    cubit.setThemeMode(ThemeMode.system);
    cubit.setAccent(AppAccent.pink);
    cubit.setAmoledBlack(false);
    cubit.setLocale(const Locale('en'));

    expect(cubit.state.themeMode, ThemeMode.system);
    expect(cubit.state.accent, AppAccent.pink);
    expect(cubit.state.amoledBlack, isFalse);
    expect(cubit.state.locale, const Locale('en'));
    expect(service.getThemeMode(), ThemeMode.system);
    expect(service.getAccent(), AppAccent.pink);
    expect(service.getAmoledBlack(), isFalse);
    expect(service.getLanguageCode(), 'en');
  });

  test('setting the same value does not emit', () async {
    final cubit = ThemeCubit(service);
    var emissions = 0;
    cubit.stream.listen((_) => emissions++);

    cubit.setThemeMode(ThemeMode.dark);
    cubit.setAccent(AppAccent.violet);
    cubit.setAmoledBlack(true);
    await Future<void>.delayed(Duration.zero);

    expect(emissions, 0);
  });
}
