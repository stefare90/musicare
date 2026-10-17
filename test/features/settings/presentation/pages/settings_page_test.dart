import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/audio_source_test_helpers.dart';
import '../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeCubit themeCubit;
  late PreferencesService preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
    themeCubit = ThemeCubit(preferences);
  });

  Widget buildTestableWidget({
    MetadataPluginCubit? metadataCubit,
    AudioSourcePluginCubit? audioCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<MetadataPluginCubit>.value(
          value: metadataCubit ?? buildMockMetadataPluginCubit(),
        ),
        BlocProvider<AudioSourcePluginCubit>.value(
          value: audioCubit ?? buildMockAudioSourcePluginCubit(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsPage(),
      ),
    );
  }

  testWidgets('lists the active plugins with their type and version', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Plugins'), findsOneWidget);
    expect(find.text('Test Provider'), findsOneWidget);
    expect(find.text('Metadata · v1.0.0'), findsOneWidget);
    expect(find.text('Test Audio'), findsOneWidget);
    expect(find.text('Audio source · v1.0.0'), findsOneWidget);
  });

  testWidgets('shows a type placeholder when a plugin is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataCubit: buildMockMetadataPluginCubit(
          state: MetadataPluginNotConfiguredState(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Not configured'), findsOneWidget);
  });

  testWidgets('shows the appearance, language and about sections', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Accent color'), findsOneWidget);
    expect(find.text('Violet'), findsOneWidget);
    expect(find.text('Absolute black'), findsOneWidget);

    await tester.tap(find.text('Violet'));
    await tester.pumpAndSettle();
    for (final accent in AppAccent.values) {
      final label = accent.name[0].toUpperCase() + accent.name.substring(1);
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Violet').last);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0.0, -800.0));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('About MusicAre'), findsOneWidget);
  });

  testWidgets('persists the selected theme mode', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();

    expect(themeCubit.state.themeMode, ThemeMode.light);
    expect(preferences.getThemeMode(), ThemeMode.light);
  });

  testWidgets('persists the selected accent', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Violet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue').last);
    await tester.pumpAndSettle();

    expect(themeCubit.state.accent, AppAccent.blue);
    expect(preferences.getAccent(), AppAccent.blue);
  });

  testWidgets('toggles absolute black and persists it', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final switchFinder = find.byType(SwitchListTile);
    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(themeCubit.state.amoledBlack, isFalse);
    expect(preferences.getAmoledBlack(), isFalse);
  });
}
