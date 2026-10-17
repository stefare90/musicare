import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('theme cubit drives the MaterialApp theme mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ThemeCubit(
      PreferencesService(await SharedPreferences.getInstance()),
    );

    await tester.pumpWidget(
      BlocProvider<ThemeCubit>.value(
        value: cubit,
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) => MaterialApp(
            theme: AppTheme.lightThemeOf(state.accent),
            darkTheme: AppTheme.darkThemeOf(
              state.accent,
              amoled: state.amoledBlack,
            ),
            themeMode: state.themeMode,
            home: Builder(
              builder: (context) => Text(
                'brightness:${Theme.of(context).brightness}',
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('brightness:Brightness.dark'), findsOneWidget);

    cubit.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();

    expect(find.text('brightness:Brightness.light'), findsOneWidget);
  });
}
