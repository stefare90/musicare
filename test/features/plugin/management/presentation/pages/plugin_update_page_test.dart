import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/pages/plugin_update_page.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';

import '../../../../../helpers/plugin_session_cubit_test_helpers.dart';
import '../../../../../helpers/plugin_manager_test_helpers.dart';

class MockPluginCatalog extends Mock implements PluginCatalog {}

void main() {
  final sl = GetIt.instance;

  late MockPluginCatalog catalog;
  late PluginManagerCubit management;

  final obsolete = PluginManifest(
    id: 'old.plugin',
    packageId: 'old_package',
    type: 'metadata',
    name: 'Old Provider',
    version: '1.0.0',
    pluginSdkVersion: '1.0.0',
    author: 'Tester',
    description: 'Obsolete',
  );
  final replacement = PluginManifest(
    id: 'new.plugin',
    packageId: 'new_package',
    type: 'metadata',
    name: 'New Provider',
    version: '2.0.0',
    pluginSdkVersion: '6.0.0',
    author: 'Tester',
    description: 'Replacement',
  );

  setUpAll(() {
    registerFallbackValue(obsolete);
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() async {
    await sl.reset();
    catalog = MockPluginCatalog();
    sl.registerSingleton<PluginCatalog>(catalog);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildTestableWidget() {
    when(
      () => catalog.latest(
        PluginType.metadata,
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => {replacement.id: replacement});

    management = buildMockPluginManagerCubit(
      state: testManagerState(
        metadataSlot: testPluginSlot(installed: obsolete, incompatible: true),
        audioSourceSlot: testPluginSlot(),
      ),
    );
    when(
      () => management.change(PluginType.metadata, replacement),
    ).thenAnswer((_) async {});

    return MultiBlocProvider(
      providers: [
        BlocProvider<PluginManagerCubit>.value(value: management),
        BlocProvider<PluginSessionCubit>.value(
          value: buildTestPluginSessionCubit(
            metadata: testRuntimeIncompatible(obsolete),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PluginUpdatePage(type: PluginType.metadata),
      ),
    );
  }

  testWidgets('renders the obsolete plugin warning and the catalog', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Action Required'), findsOneWidget);
    expect(find.text('Obsolete Provider'), findsOneWidget);
    expect(find.text('Old Provider'), findsOneWidget);
    expect(find.text('Installed version: v1.0.0'), findsOneWidget);
    expect(find.byType(PluginDiscoveryWidget), findsOneWidget);
    expect(find.text('Replace…'), findsOneWidget);
  });

  testWidgets('forwarding a replacement asks for confirmation and changes it', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Replace…'));
    await tester.pumpAndSettle();
    expect(find.text('Replace plugin?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Replace…'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => management.change(PluginType.metadata, replacement)).called(1);
  });
}
