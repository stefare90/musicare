import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class MockMetadataPluginCubit extends Mock implements MetadataPluginCubit {}

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

void main() {
  final sl = GetIt.instance;

  late MockMetadataPluginCubit mockPluginCubit;
  late MockPluginDiscoveryService mockDiscoveryService;

  setUpAll(() {
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() async {
    await sl.reset();
    mockPluginCubit = MockMetadataPluginCubit();
    mockDiscoveryService = MockPluginDiscoveryService();

    sl.registerLazySingleton<PluginDiscoveryService>(
      () => mockDiscoveryService,
    );

    when(
      () => mockPluginCubit.state,
    ).thenReturn(MetadataPluginNotConfiguredState());
    when(() => mockPluginCubit.stream).thenAnswer((_) => const Stream.empty());

    when(
      () =>
          mockDiscoveryService.fetchCommunityPlugins(type: any(named: 'type')),
    ).thenAnswer((_) async => []);
  });

  Widget buildTestableWidget({required GoRouter router}) {
    return BlocProvider<MetadataPluginCubit>.value(
      value: mockPluginCubit,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('WelcomePage Widget Tests', () {
    testWidgets(
      'renders titles, app slogan and metadata plugin discovery widget',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/welcome',
          routes: [
            GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
          ],
        );

        await tester.pumpWidget(buildTestableWidget(router: router));
        await tester.pumpAndSettle();

        expect(find.text('Welcome to MusicAre'), findsOneWidget);
        expect(
          find.text('Music are the plugins. We are the player.'),
          findsOneWidget,
        );
        expect(find.text('Community Plugins (GitHub)'), findsOneWidget);
      },
    );

    testWidgets('navigates to / when MetadataPluginLoadedState is emitted', (
      tester,
    ) async {
      final streamController =
          StreamController<MetadataPluginState>.broadcast();
      when(
        () => mockPluginCubit.stream,
      ).thenAnswer((_) => streamController.stream);

      bool navigatedToHome = false;

      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
          GoRoute(
            path: '/',
            builder: (_, __) {
              navigatedToHome = true;
              return const Scaffold(body: Text('Home Page Placeholder'));
            },
          ),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(router: router));
      await tester.pumpAndSettle();

      final loadedManifest = PluginManifest(
        id: 'org.gyawun.musicbrainz',
        packageId: 'gyawun_metadata_plugin',
        type: 'metadata',
        name: 'MusicBrainz',
        version: '1.0.0',
        pluginSdkVersion: '1.0.0',
        author: 'MusicAre Team',
        description: 'Test',
      );

      streamController.add(MetadataPluginLoadingState());
      await tester.pump();

      streamController.add(
        MetadataPluginLoadedState(
          manifest: loadedManifest,
          isAuthenticated: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(navigatedToHome, isTrue);
      expect(find.text('Home Page Placeholder'), findsOneWidget);

      await streamController.close();
    });
  });
}
