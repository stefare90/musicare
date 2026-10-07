import 'dart:async';

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
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';

class MockMetadataPluginCubit extends Mock implements MetadataPluginCubit {}

class MockAudioSourcePluginCubit extends Mock
    implements AudioSourcePluginCubit {}

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

void main() {
  final sl = GetIt.instance;

  late MockMetadataPluginCubit mockMetadataCubit;
  late MockAudioSourcePluginCubit mockAudioSourceCubit;
  late MockPluginDiscoveryService mockDiscoveryService;
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
    mockMetadataCubit = MockMetadataPluginCubit();
    mockAudioSourceCubit = MockAudioSourcePluginCubit();
    mockDiscoveryService = MockPluginDiscoveryService();

    sl.registerLazySingleton<PluginDiscoveryService>(
      () => mockDiscoveryService,
    );
    bus = NoticeBus();
    sl.registerLazySingleton<NoticeBus>(() => bus);

    when(
      () => mockMetadataCubit.state,
    ).thenReturn(MetadataPluginNotConfiguredState());
    when(
      () => mockMetadataCubit.stream,
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => mockAudioSourceCubit.state,
    ).thenReturn(AudioSourcePluginNotConfiguredState());
    when(
      () => mockAudioSourceCubit.stream,
    ).thenAnswer((_) => const Stream.empty());

    when(
      () =>
          mockDiscoveryService.fetchCommunityPlugins(type: any(named: 'type')),
    ).thenAnswer((_) async => []);
  });

  Widget buildTestableWidget({required GoRouter router}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MetadataPluginCubit>.value(value: mockMetadataCubit),
        BlocProvider<AudioSourcePluginCubit>.value(value: mockAudioSourceCubit),
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
      final metadataStream = StreamController<MetadataPluginState>.broadcast();
      when(
        () => mockMetadataCubit.stream,
      ).thenAnswer((_) => metadataStream.stream);

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

      when(() => mockMetadataCubit.state).thenReturn(
        MetadataPluginLoadedState(
          manifest: metadataManifest,
        ),
      );
      metadataStream.add(
        MetadataPluginLoadedState(
          manifest: metadataManifest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue to Audio Source'), findsOneWidget);

      await tester.tap(find.text('Continue to Audio Source'));
      await tester.pumpAndSettle();

      expect(find.text('Audio Stream Provider'), findsOneWidget);

      await metadataStream.close();
    });

    testWidgets(
      'shows finish setup button on Page 2 and navigates to / on tap',
      (tester) async {
        when(() => mockMetadataCubit.state).thenReturn(
          MetadataPluginLoadedState(
            manifest: metadataManifest,
          ),
        );
        when(() => mockAudioSourceCubit.state).thenReturn(
          AudioSourcePluginLoadedState(manifest: audioManifest, port: 8765),
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

    testWidgets('shows an error snackbar on metadata plugin error', (
      tester,
    ) async {
      final metadataStream = StreamController<MetadataPluginState>.broadcast();
      when(
        () => mockMetadataCubit.stream,
      ).thenAnswer((_) => metadataStream.stream);

      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(router: router));
      await tester.pumpAndSettle();

      metadataStream.add(
        MetadataPluginErrorState(Exception('Download failure')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('An unexpected error occurred: Download failure'),
        findsOneWidget,
      );

      await metadataStream.close();
    });
  });
}
