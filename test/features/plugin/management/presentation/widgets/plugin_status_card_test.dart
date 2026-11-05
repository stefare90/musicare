import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/core/theme/app_semantic_colors.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/features/plugin/management/presentation/widgets/plugin_status_card.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_lifecycle_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

void main() {
  final manifest = PluginManifest(
    id: 'old.plugin',
    packageId: 'old_package',
    type: 'metadata',
    name: 'Old Provider',
    version: '1.0.0',
    pluginSdkVersion: '1.0.0',
    author: 'Tester',
    description: 'Obsolete',
  );

  Widget buildTestableWidget(PluginStatusCard card, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: card),
    );
  }

  testWidgets('an incompatible plugin shows its name and installed version', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PluginStatusCard(
          status: PluginLifecycleStatus.incompatible,
          type: PluginType.metadata,
          manifest: manifest,
        ),
      ),
    );

    expect(find.text('Obsolete Provider'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Old Provider'), findsOneWidget);
    expect(find.text('Installed version: v1.0.0'), findsOneWidget);
    expect(
      find.text(
        'This provider is no longer compatible with the current version of '
        'MusicAre and must be updated to continue.',
      ),
      findsOneWidget,
    );
    expect(find.text('Not installed'), findsNothing);
  });

  testWidgets('an incompatible plugin without a manifest still explains', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const PluginStatusCard(
          status: PluginLifecycleStatus.incompatible,
          type: PluginType.metadata,
        ),
      ),
    );

    expect(find.text('Obsolete Provider'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Installed version: v1.0.0'), findsNothing);
    expect(
      find.text(
        'This provider is no longer compatible with the current version of '
        'MusicAre and must be updated to continue.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a plugin that did not start is not reported as missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PluginStatusCard(
          status: PluginLifecycleStatus.error,
          type: PluginType.metadata,
          manifest: manifest,
        ),
      ),
    );

    expect(find.text('Could not load'), findsOneWidget);
    expect(find.text('Not installed'), findsNothing);
    expect(find.text('Old Provider'), findsOneWidget);
    expect(find.text('Installed version: v1.0.0'), findsOneWidget);
    expect(
      find.text(
        'The plugin is installed but did not start. Reinstall or replace it '
        'below.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a missing plugin explains what the type is needed for', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const PluginStatusCard(
          status: PluginLifecycleStatus.notConfigured,
          type: PluginType.metadata,
        ),
      ),
    );

    expect(find.text('Not installed'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(
      find.text('Needed to browse albums, artists and playlists.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const PluginStatusCard(
          status: PluginLifecycleStatus.notConfigured,
          type: PluginType.audioSource,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Audio source'), findsOneWidget);
    expect(find.text('Needed to play tracks.'), findsOneWidget);
  });

  testWidgets('a missing plugin uses the warning colour, never the accent', (
    tester,
  ) async {
    final theme = AppTheme.darkThemeOf(AppAccent.green);
    await tester.pumpWidget(
      buildTestableWidget(
        const PluginStatusCard(
          status: PluginLifecycleStatus.notConfigured,
          type: PluginType.metadata,
        ),
        theme: theme,
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AppSemanticColors.of(Brightness.dark).warning);
    expect(icon.color, isNot(theme.colorScheme.primary));
  });
}
