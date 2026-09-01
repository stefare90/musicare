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
    testWidgets(
      'renders manifest details and Install & Activate button when not active',
      (tester) async {
        PluginManifest? tappedManifest;

        await tester.pumpWidget(
          buildTestableWidget(
            child: PluginManifestCard(
              manifest: testManifest,
              isActive: false,
              onInstallTap: (manifest) => tappedManifest = manifest,
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
        await tester.pumpAndSettle();

        expect(tappedManifest, equals(testManifest));
      },
    );

    testWidgets(
      'renders Active badge and disabled button when isActive is true',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: PluginManifestCard(manifest: testManifest, isActive: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Active'),
          findsNWidgets(2),
        ); // Badge in alto + testo pulsante
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(find.text('Install & Activate'), findsNothing);

        // Verifica che il pulsante sia disabilitato (OutlinedButton con onPressed: null)
        final outlinedButton = tester.widget<OutlinedButton>(
          find.byType(OutlinedButton),
        );
        expect(outlinedButton.onPressed, isNull);
      },
    );
  });
}
