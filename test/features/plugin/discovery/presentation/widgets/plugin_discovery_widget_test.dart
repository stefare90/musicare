import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class MockPluginCatalog extends Mock implements PluginCatalog {}

PluginManifest manifest({
  String id = 'org.musicare.metadata.test',
  String version = '1.0.0',
}) => PluginManifest(
  id: id,
  packageId: 'test_plugin',
  type: 'metadata',
  name: 'Test Plugin',
  version: version,
  pluginSdkVersion: '1.0.0',
  author: 'Tester',
  description: 'Test plugin description',
);

void main() {
  final sl = GetIt.instance;

  late MockPluginCatalog catalog;
  late List<PluginManifest> actions;

  setUpAll(() {
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() async {
    await sl.reset();
    catalog = MockPluginCatalog();
    actions = [];
    sl.registerSingleton<PluginCatalog>(catalog);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildTestableWidget({
    PluginManifest? installed,
    PluginManifest? remote,
  }) {
    when(
      () => catalog.latest(
        PluginType.metadata,
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => remote == null ? {} : {remote.id: remote});

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PluginDiscoveryWidget(
            pluginType: PluginType.metadata,
            installed: installed,
            onSelected: (manifest) async {
              actions.add(manifest);
            },
          ),
        ),
      ),
    );
  }

  testWidgets('offers install for a plugin with nothing installed', (
    tester,
  ) async {
    final remote = manifest();
    await tester.pumpWidget(buildTestableWidget(remote: remote));
    await tester.pumpAndSettle();

    expect(find.text('Test Plugin'), findsOneWidget);
    expect(find.text('Install & Activate'), findsOneWidget);

    await tester.tap(find.text('Install & Activate'));
    await tester.pumpAndSettle();

    expect(actions.single, remote);
  });

  testWidgets('offers an update when the catalog has a newer version', (
    tester,
  ) async {
    final installed = manifest(version: '1.0.0');
    final remote = manifest(version: '2.0.0');
    await tester.pumpWidget(
      buildTestableWidget(installed: installed, remote: remote),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update to v2.0.0'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.text('Update to v2.0.0'));
    await tester.pumpAndSettle();

    expect(actions.single, remote);
  });

  testWidgets('asks for confirmation before replacing the installed plugin', (
    tester,
  ) async {
    final installed = manifest(id: 'org.musicare.metadata.old');
    final remote = manifest(id: 'org.musicare.metadata.new');
    await tester.pumpWidget(
      buildTestableWidget(installed: installed, remote: remote),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Replace…'));
    await tester.pumpAndSettle();

    expect(find.text('Replace plugin?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);

    await tester.tap(find.text('Replace…'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Replace…'),
      ),
    );
    await tester.pumpAndSettle();

    expect(actions.single, remote);
  });
}
