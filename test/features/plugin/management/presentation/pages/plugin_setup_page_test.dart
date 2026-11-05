import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/management/data/models/plugin_slot_data.dart';
import 'package:music_are/features/plugin/management/data/services/plugin_manager.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/management/presentation/pages/plugin_setup_page.dart';
import 'package:music_are/features/plugin/management/presentation/widgets/plugin_status_card.dart';
import 'package:music_are/features/plugin/shared/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';

import '../../../../../helpers/error_presentation_test_helpers.dart';
import '../../../../../helpers/plugin_manager_test_helpers.dart';
import '../../../../../helpers/plugin_session_cubit_test_helpers.dart';

class MockPluginCatalog extends Mock implements PluginCatalog {}

/// Only `snapshot` matters here; everything else is out of scope.
class FakePluginManager implements PluginManager {
  FakePluginManager(this.slots);

  final Map<PluginType, PluginSlotData> slots;

  @override
  Future<PluginSlotData> snapshot(
    PluginType type, {
    bool fetchCatalog = true,
    bool forceRefresh = false,
  }) async => slots[type] ?? const PluginSlotData();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  final sl = GetIt.instance;

  late MockPluginCatalog catalog;
  late PluginManagerCubit management;
  late TestPluginSessionCubit session;
  late StreamController<PluginManagerState> managerEvents;

  final metadataInstalled = PluginManifest(
    id: 'metadata.plugin',
    packageId: 'metadata_package',
    type: 'metadata',
    name: 'Metadata Provider',
    version: '2.0.0',
    pluginSdkVersion: '6.0.0',
    author: 'Tester',
    description: 'Metadata',
  );
  final obsoleteMetadata = PluginManifest(
    id: 'old.plugin',
    packageId: 'old_package',
    type: 'metadata',
    name: 'Old Provider',
    version: '1.0.0',
    pluginSdkVersion: '1.0.0',
    author: 'Tester',
    description: 'Obsolete',
  );
  final audioInstalled = PluginManifest(
    id: 'audio.plugin',
    packageId: 'audio_package',
    type: 'audio_source',
    name: 'Audio Provider',
    version: '1.0.0',
    pluginSdkVersion: '6.0.0',
    author: 'Tester',
    description: 'Audio',
  );

  setUpAll(() {
    registerFallbackValue(metadataInstalled);
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() async {
    await sl.reset();
    catalog = MockPluginCatalog();
    sl.registerSingleton<PluginCatalog>(catalog);
    registerTestErrorPresentation();
    when(
      () => catalog.latest(any(), forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => {});
    managerEvents = StreamController<PluginManagerState>.broadcast();
  });

  tearDown(() async {
    await managerEvents.close();
    await sl.reset();
  });

  MockPluginManagerCubit managerMock(
    PluginLifecycleState? metadataState,
    PluginLifecycleState? audioState,
    PluginManagerState? managerState,
  ) {
    final mock = MockPluginManagerCubit();
    when(() => mock.state).thenReturn(
      managerState ??
          testManagerState(
            metadata: metadataState?.manifest,
            audioSource: audioState?.manifest,
          ),
    );
    when(() => mock.stream).thenAnswer((_) => managerEvents.stream);
    when(() => mock.change(any(), any())).thenAnswer((_) async {});
    when(
      () => mock.refresh(
        force: any(named: 'force'),
        fetchCatalog: any(named: 'fetchCatalog'),
      ),
    ).thenAnswer((_) async {});
    return mock;
  }

  Widget buildTestableWidget({
    PluginLifecycleState? metadataState,
    PluginLifecycleState? audioState,
    PluginManagerState? managerState,
    PluginManagerCubit? managerCubit,
  }) {
    session = buildTestPluginSessionCubit(
      metadata: metadataState,
      audioSource: audioState,
    );
    management = managerCubit ?? managerMock(metadataState, audioState, managerState);

    return MultiBlocProvider(
      providers: [
        BlocProvider<PluginManagerCubit>.value(value: management),
        BlocProvider<PluginSessionCubit>.value(value: session),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: AppRoutes.pluginSetup,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const Text('Home stub'),
            ),
            GoRoute(
              path: AppRoutes.pluginSetup,
              builder: (context, state) => const PluginSetupPage(),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('a missing metadata plugin shows only the metadata slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: const PluginLifecycleState.notConfigured(),
        audioState: testRuntimeLoaded(audioInstalled),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Action Required'), findsOneWidget);
    expect(find.text('Not installed'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(
      find.text('Needed to browse albums, artists and playlists.'),
      findsOneWidget,
    );
    expect(find.text('Metadata plugins on GitHub'), findsOneWidget);
    expect(find.text('Audio source'), findsNothing);
    expect(find.byType(PluginDiscoveryWidget), findsOneWidget);
  });

  testWidgets('a missing audio plugin shows only the audio slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: testRuntimeLoaded(metadataInstalled),
        audioState: const PluginLifecycleState.notConfigured(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audio source'), findsOneWidget);
    expect(find.text('Needed to play tracks.'), findsOneWidget);
    expect(find.text('Audio source plugins on GitHub'), findsOneWidget);
    expect(find.text('Metadata'), findsNothing);
    expect(find.byType(PluginDiscoveryWidget), findsOneWidget);
  });

  testWidgets('two pending slots are numbered and summarised', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: const PluginLifecycleState.notConfigured(),
        audioState: const PluginLifecycleState.notConfigured(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Audio source'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.byType(PluginDiscoveryWidget), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Metadata')).dy,
      lessThan(tester.getTopLeft(find.text('Audio source')).dy),
    );
  });

  testWidgets('no pending slot navigates to Home', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: testRuntimeLoaded(metadataInstalled),
        audioState: testRuntimeLoaded(audioInstalled),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home stub'), findsOneWidget);
    expect(find.byType(PluginSetupPage), findsNothing);
  });

  testWidgets('an incompatible slot and a missing one use the same card', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: testRuntimeIncompatible(obsoleteMetadata),
        audioState: const PluginLifecycleState.notConfigured(),
        managerState: testManagerState(
          metadataSlot: testPluginSlot(
            installed: obsoleteMetadata,
            incompatible: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<PluginStatusCard>(find.byType(PluginStatusCard))
        .toList();
    expect(cards.map((card) => card.status), [
      PluginLifecycleStatus.incompatible,
      PluginLifecycleStatus.notConfigured,
    ]);
    expect(find.text('Obsolete Provider'), findsOneWidget);
    expect(find.text('Old Provider'), findsOneWidget);
    expect(find.text('Installed version: v1.0.0'), findsOneWidget);
    expect(
      find.text(
        'This provider is no longer compatible with the current version of '
        'MusicAre and must be updated to continue.',
      ),
      findsOneWidget,
    );
    expect(find.text('Not installed'), findsOneWidget);
    expect(find.text('Needed to play tracks.'), findsOneWidget);
  });

  testWidgets('an installed plugin that did not start says so', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: testRuntimeFailure(Exception('boot failed')),
        audioState: testRuntimeLoaded(audioInstalled),
        managerState: testManagerState(
          metadataSlot: testPluginSlot(installed: obsoleteMetadata),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load'), findsOneWidget);
    expect(find.text('Not installed'), findsNothing);
    expect(find.text('Old Provider'), findsOneWidget);
    expect(find.text('Installed version: v1.0.0'), findsOneWidget);
  });

  testWidgets('a busy slot shows the loading dialog until it settles', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: testRuntimeIncompatible(obsoleteMetadata),
        audioState: const PluginLifecycleState.notConfigured(),
        managerState: testManagerState(
          metadataSlot: testPluginSlot(
            installed: obsoleteMetadata,
            incompatible: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    managerEvents.add(
      testManagerState(
        metadataSlot: testPluginSlot(
          installed: obsoleteMetadata,
          incompatible: true,
          phase: PluginSlotPhase.busy,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Installing and initializing plugin...'), findsOneWidget);

    managerEvents.add(
      testManagerState(
        metadataSlot: testPluginSlot(
          installed: metadataInstalled,
          phase: PluginSlotPhase.idle,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Installing and initializing plugin...'), findsNothing);
  });

  testWidgets('one loaded slot keeps setup open until the other is ready', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: testRuntimeIncompatible(obsoleteMetadata),
        audioState: testRuntimeIncompatible(audioInstalled),
        managerState: testManagerState(
          metadataSlot: testPluginSlot(
            installed: obsoleteMetadata,
            incompatible: true,
          ),
          audioSourceSlot: testPluginSlot(
            installed: audioInstalled,
            incompatible: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Audio source'), findsOneWidget);

    session.setState(
      PluginType.metadata,
      testRuntimeLoaded(metadataInstalled),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PluginSetupPage), findsOneWidget);
    expect(find.text('Home stub'), findsNothing);
    expect(find.text('Metadata'), findsNothing);
    expect(find.text('Audio source'), findsOneWidget);
  });

  testWidgets('an installed plugin that did not start is not offered as new', (
    tester,
  ) async {
    // The page opens on boot, before anything refreshed the manager: the slot
    // has no manifest, so the card used to read "Not installed" and the
    // catalog used to offer Install & Activate for an installed plugin.
    when(
      () => catalog.latest(any(), forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => {obsoleteMetadata.id: obsoleteMetadata});

    final manager = FakePluginManager({
      PluginType.metadata: PluginSlotData(installed: obsoleteMetadata),
    });
    final cubit = PluginManagerCubit(manager, NoticeBus());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      buildTestableWidget(
        metadataState: testRuntimeFailure(Exception('boot failed')),
        audioState: testRuntimeLoaded(audioInstalled),
        managerCubit: cubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Old Provider'), findsNWidgets(2));
    expect(find.text('Installed version: v1.0.0'), findsOneWidget);
    expect(find.text('Not installed'), findsNothing);
    expect(find.text('Install & Activate'), findsNothing);
    expect(find.text('Reinstall'), findsOneWidget);
  });
}
