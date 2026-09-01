import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

class MockMetadataPluginCubit extends Mock implements MetadataPluginCubit {}

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
  late MockMetadataPluginCubit mockPluginCubit;

  setUpAll(() {
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() async {
    await sl.reset();
    mockDiscoveryService = MockPluginDiscoveryService();
    mockPluginCubit = MockMetadataPluginCubit();

    sl.registerLazySingleton<PluginDiscoveryService>(
      () => mockDiscoveryService,
    );

    when(
      () => mockPluginCubit.state,
    ).thenReturn(MetadataPluginNotConfiguredState());
    when(() => mockPluginCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestableWidget() {
    return BlocProvider<MetadataPluginCubit>.value(
      value: mockPluginCubit,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: PluginDiscoveryWidget()),
        ),
      ),
    );
  }

  group('PluginDiscoveryWidget Tests', () {
    testWidgets('renders list of plugins when loaded successfully', (
      tester,
    ) async {
      when(
        () => mockDiscoveryService.fetchCommunityPlugins(
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => [testManifest]);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('MusicBrainz & ListenBrainz'), findsOneWidget);
      expect(find.text('By MusicAre Team'), findsOneWidget);
      expect(find.text('Test plugin description'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('Install & Activate'), findsOneWidget);
    });

    testWidgets(
      'triggers installDiscoveredPlugin on MetadataPluginCubit when button tapped',
      (tester) async {
        when(
          () => mockDiscoveryService.fetchCommunityPlugins(
            type: any(named: 'type'),
          ),
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
