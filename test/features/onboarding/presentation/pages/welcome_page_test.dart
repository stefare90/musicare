import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_state.dart';

class MockPluginCubit extends Mock implements PluginCubit {}

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

void main() {
  final sl = GetIt.instance;

  late MockPluginCubit mockPluginCubit;
  late MockPluginDiscoveryService mockDiscoveryService;

  setUp(() async {
    await sl.reset();
    mockPluginCubit = MockPluginCubit();
    mockDiscoveryService = MockPluginDiscoveryService();

    sl.registerLazySingleton<PluginDiscoveryService>(
      () => mockDiscoveryService,
    );

    when(() => mockPluginCubit.state).thenReturn(PluginNotConfiguredState());
    when(() => mockPluginCubit.stream).thenAnswer((_) => const Stream.empty());

    when(
      () => mockDiscoveryService.fetchCommunityPlugins(),
    ).thenAnswer((_) async => []);
  });

  Widget buildTestableWidget({required GoRouter router}) {
    return BlocProvider<PluginCubit>.value(
      value: mockPluginCubit,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('WelcomePage Widget Tests', () {
    testWidgets('renders titles, app slogan and plugin discovery widget', (
      tester,
    ) async {
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
      expect(
        find.text('Select a music metadata provider to get started'),
        findsOneWidget,
      );
      expect(find.text('Community Plugins (GitHub)'), findsOneWidget);
    });

    testWidgets(
      'navigates to / when PluginLoadedState is emitted after loading',
      (tester) async {
        final streamController = StreamController<PluginState>.broadcast();
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

        streamController.add(PluginLoadingState());
        await tester.pump();

        streamController.add(
          PluginLoadedState(manifest: loadedManifest, isAuthenticated: false),
        );
        await tester.pumpAndSettle();

        expect(navigatedToHome, isTrue);
        expect(find.text('Home Page Placeholder'), findsOneWidget);

        await streamController.close();
      },
    );

    testWidgets(
      'displays SnackBar when PluginErrorState is emitted after loading',
      (tester) async {
        final streamController = StreamController<PluginState>.broadcast();
        when(
          () => mockPluginCubit.stream,
        ).thenAnswer((_) => streamController.stream);

        final router = GoRouter(
          initialLocation: '/welcome',
          routes: [
            GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
          ],
        );

        await tester.pumpWidget(buildTestableWidget(router: router));
        await tester.pumpAndSettle();

        streamController.add(PluginLoadingState());
        await tester.pump();

        streamController.add(PluginErrorState(Exception('Download failed')));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('An unexpected error occurred: Download failed'),
          findsOneWidget,
        );

        await streamController.close();
      },
    );

    testWidgets(
      'safely handles PluginLoadedState emitted directly without prior loading dialog',
      (tester) async {
        final streamController = StreamController<PluginState>.broadcast();
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

        streamController.add(
          PluginLoadedState(manifest: loadedManifest, isAuthenticated: false),
        );
        await tester.pumpAndSettle();

        expect(navigatedToHome, isTrue);
        expect(find.text('Home Page Placeholder'), findsOneWidget);

        await streamController.close();
      },
    );

    testWidgets(
      'safely handles PluginErrorState emitted directly without prior loading dialog',
      (tester) async {
        final streamController = StreamController<PluginState>.broadcast();
        when(
          () => mockPluginCubit.stream,
        ).thenAnswer((_) => streamController.stream);

        final router = GoRouter(
          initialLocation: '/welcome',
          routes: [
            GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
          ],
        );

        await tester.pumpWidget(buildTestableWidget(router: router));
        await tester.pumpAndSettle();

        streamController.add(PluginErrorState(Exception('Direct error')));
        await tester.pumpAndSettle();

        expect(find.text('Welcome to MusicAre'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);

        await streamController.close();
      },
    );
  });
}
