import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/settings/presentation/pages/settings_page.dart';

import '../../../../helpers/audio_source_test_helpers.dart';
import '../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  Widget buildTestableWidget({
    MetadataPluginCubit? metadataCubit,
    AudioSourcePluginCubit? audioCubit,
  }) {
    return MultiBlocProvider(
      providers: [
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
}
