import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_manifest_card.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

void main() {
  final testManifest = PluginManifest(
    id: 'org.gyawun.musicbrainz',
    packageId: 'gyawun_metadata_plugin',
    type: 'metadata',
    name: 'MusicBrainz & ListenBrainz',
    version: '1.0.0',
    pluginSdkVersion: '1.0.0',
    author: 'MusicAre Team',
    description: 'Test description',
  );

  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('PluginManifestCard Widget Tests', () {
    testWidgets('renders the manifest and the install action', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        buildTestableWidget(
          child: PluginManifestCard(
            manifest: testManifest,
            onAction: () => taps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MusicBrainz & ListenBrainz'), findsOneWidget);
      expect(find.text('By MusicAre Team'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('Install & Activate'), findsOneWidget);

      await tester.tap(find.text('Install & Activate'));
      expect(taps, 1);
    });

    testWidgets('renders Active badge and Reinstall for the installed plugin', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: PluginManifestCard(
            manifest: testManifest,
            isActive: true,
            action: PluginAction.reinstall,
            onAction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Reinstall'), findsOneWidget);
      expect(find.text('Install & Activate'), findsNothing);

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('labels an update with the target version', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: PluginManifestCard(
            manifest: PluginManifest(
              id: testManifest.id,
              packageId: testManifest.packageId,
              type: testManifest.type,
              name: testManifest.name,
              version: '2.0.0',
              pluginSdkVersion: testManifest.pluginSdkVersion,
              author: testManifest.author,
              description: testManifest.description,
            ),
            action: PluginAction.update,
            onAction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update to v2.0.0'), findsOneWidget);
    });

    testWidgets('labels a different plugin as Replace', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: PluginManifestCard(
            manifest: testManifest,
            action: PluginAction.replace,
            onAction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replace…'), findsOneWidget);
    });
  });
}
