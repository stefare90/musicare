import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_dots_indicator.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';

import '../../../../helpers/plugin_session_cubit_test_helpers.dart';
import '../../../../helpers/plugin_manager_test_helpers.dart';

class MockPluginCatalog extends Mock implements PluginCatalog {}

void main() {
  final sl = GetIt.instance;

  late MockPluginCatalog mockCatalog;
  late TestPluginSessionCubit pluginCubit;
  late NoticeBus bus;

  final metadataManifest = PluginManifest(
    id: 'org.gyawun.musicbrainz',
    packageId: 'gyawun_metadata_plugin',
    type: 'metadata',
    name: 'MusicBrainz & ListenBrainz',
    version: '1.0.0',
    pluginSdkVersion: '1.0.0',
    author: 'MusicAre Team',
    description: 'Metadata provider',
  );

  final audioManifest = PluginManifest(
    id: 'org.musicare.audiosource.youtube',
    packageId: 'musicare_audiosource_youtube_plugin',
    type: 'audioSource',
    name: 'YouTube Audio Source',
    version: '1.0.0',
    pluginSdkVersion: '1.0.0',
    author: 'MusicAre Team',
    description: 'Audio stream provider',
  );

  setUpAll(() {
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() async {
    await sl.reset();
    mockCatalog = MockPluginCatalog();
    pluginCubit = buildTestPluginSessionCubit();
    sl.registerLazySingleton<PluginCatalog>(() => mockCatalog);
    bus = NoticeBus();
    sl.registerLazySingleton<NoticeBus>(() => bus);
    when(
      () => mockCatalog.latest(any(), forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => {});
  });

  Widget buildTestableWidget({required GoRouter router}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PluginSessionCubit>.value(value: pluginCubit),
        BlocProvider<PluginManagerCubit>.value(
          value: buildMockPluginManagerCubit(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Scaffold(
          resizeToAvoidBottomInset: false,
          body: NoticeListener(
            notices: bus.notices,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        routerConfig: router,
      ),
    );
  }

  group('WelcomePage 3-Page Flow Tests', () {
    testWidgets('renders Page 0 (Intro) and advances to Page 1 on button tap', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to MusicAre'), findsOneWidget);
      expect(
        find.text('Music are the plugins. We are the player.'),
        findsOneWidget,
      );
      expect(find.text('Select Metadata Provider'), findsOneWidget);
      expect(find.byType(OnboardingDotsIndicator), findsOneWidget);

      await tester.tap(find.text('Select Metadata Provider'));
      await tester.pumpAndSettle();

      expect(find.text('Metadata Provider'), findsOneWidget);
    });

    testWidgets('back arrow navigates to previous page', (tester) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select Metadata Provider'));
      await tester.pumpAndSettle();
      expect(find.text('Metadata Provider'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to MusicAre'), findsOneWidget);
    });

    testWidgets('shows continue button on Page 1 when metadata is loaded', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select Metadata Provider'));
      await tester.pumpAndSettle();

      pluginCubit.setState(
        PluginType.metadata,
        testRuntimeLoaded(metadataManifest),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue to Audio Source'), findsOneWidget);

      await tester.tap(find.text('Continue to Audio Source'));
      await tester.pumpAndSettle();

      expect(find.text('Audio Stream Provider'), findsOneWidget);
    });

    testWidgets(
      'shows finish setup button on Page 2 and navigates to / on tap',
      (tester) async {
        pluginCubit.setState(
          PluginType.metadata,
          testRuntimeLoaded(metadataManifest),
        );
        pluginCubit.setState(
          PluginType.audioSource,
          testRuntimeLoaded(audioManifest, port: 8765),
        );

        bool navigatedToHome = false;

        final router = GoRouter(
          initialLocation: '/welcome',
          routes: [
            GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
            GoRoute(
              path: '/',
              builder: (_, _) {
                navigatedToHome = true;
                return const Scaffold(body: Text('Home Screen Content'));
              },
            ),
          ],
        );

        await tester.pumpWidget(buildTestableWidget(router: router));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select Metadata Provider'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continue to Audio Source'));
        await tester.pumpAndSettle();

        expect(find.text('Finish Setup'), findsOneWidget);

        await tester.tap(find.text('Finish Setup'));
        await tester.pumpAndSettle();

        expect(navigatedToHome, isTrue);
        expect(find.text('Home Screen Content'), findsOneWidget);
      },
    );
  });
}
