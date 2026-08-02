import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_state.dart';
import 'package:music_are/features/plugin/presentation/widgets/plugin_discovery_widget.dart';

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

class MockPluginCubit extends Mock implements PluginCubit {}

void main() {
  final sl = GetIt.instance;

  final testManifest = PluginManifest(
    id: 'org.gyawun.musicbrainz',
    packageId: 'gyawun_metadata_plugin',
    type: 'metadata',
    name: 'MusicBrainz & ListenBrainz',
    version: '1.0.0',
    pluginSdkVersion: '1.0.0',
    author: 'MusicAre Team',
    description: 'Test plugin description',
  );

  late MockPluginDiscoveryService mockDiscoveryService;
  late MockPluginCubit mockPluginCubit;

  setUp(() async {
    await sl.reset();
    mockDiscoveryService = MockPluginDiscoveryService();
    mockPluginCubit = MockPluginCubit();

    sl.registerLazySingleton<PluginDiscoveryService>(
      () => mockDiscoveryService,
    );

    when(() => mockPluginCubit.state).thenReturn(PluginNotConfiguredState());
    when(() => mockPluginCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestableWidget() {
    return BlocProvider<PluginCubit>.value(
      value: mockPluginCubit,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: PluginDiscoveryWidget()),
        ),
      ),
    );
  }

  group('PluginDiscoveryWidget Tests', () {
    testWidgets('renders loading state initially', (tester) async {
      final completer = Completer<List<PluginManifest>>();
      when(
        () => mockDiscoveryService.fetchCommunityPlugins(),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestableWidget());
      await tester
          .pump(); // Renderizza il frame dello stato iniziale di loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Risolviamo la Future e svuotiamo la coda del framwork prima di chiudere il test
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders list of plugins when loaded successfully', (
      tester,
    ) async {
      when(
        () => mockDiscoveryService.fetchCommunityPlugins(),
      ).thenAnswer((_) async => [testManifest]);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('MusicBrainz & ListenBrainz'), findsOneWidget);
      expect(find.text('By MusicAre Team'), findsOneWidget);
      expect(find.text('Test plugin description'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('Install & Activate'), findsOneWidget);
    });

    testWidgets('renders empty state message when no plugins found', (
      tester,
    ) async {
      when(
        () => mockDiscoveryService.fetchCommunityPlugins(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('No plugins found on GitHub tagged with "musicare-plugin".'),
        findsOneWidget,
      );
    });

    testWidgets('renders error card on failure and retries on button tap', (
      tester,
    ) async {
      when(
        () => mockDiscoveryService.fetchCommunityPlugins(),
      ).thenThrow(Exception('Network connection failed'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('An unexpected error occurred: Network connection failed'),
        findsOneWidget,
      );

      when(
        () => mockDiscoveryService.fetchCommunityPlugins(),
      ).thenAnswer((_) async => [testManifest]);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('MusicBrainz & ListenBrainz'), findsOneWidget);
    });

    testWidgets(
      'triggers installAndActivate on PluginCubit when button is tapped',
      (tester) async {
        when(
          () => mockDiscoveryService.fetchCommunityPlugins(),
        ).thenAnswer((_) async => [testManifest]);
        when(
          () => mockPluginCubit.installDiscoveredPlugin(testManifest),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Install & Activate'));
        await tester.pumpAndSettle();

        verify(
          () => mockPluginCubit.installDiscoveredPlugin(testManifest),
        ).called(1);
      },
    );
  });
}
