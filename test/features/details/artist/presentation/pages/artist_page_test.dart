import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../helpers/metadata_plugin_test_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/media/track_matrix.dart';
import 'package:music_are/features/details/artist/presentation/pages/artist_page.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockArtistService extends Mock implements IArtist {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

class MockAuthService extends Mock implements IAuth {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine mockEngine;
  late MockMetadataPlugin mockMetadata;
  late MockArtistService mockArtist;
  late MockPlayerCubit mockPlayerCubit;

  final testArtist = Artist(id: 'a1', name: 'The Beatles', externalUri: '');

  final testTrack = Track(
    id: 't1',
    name: 'Yesterday',
    externalUri: '',
    artists: [testArtist],
    album: Album(
      id: 'al1',
      name: 'Help!',
      artists: [],
      releaseDate: '1965',
      externalUri: '',
      totalTracks: 14,
      albumType: AlbumType.album,
    ),
    durationMs: 125000,
  );

  final testAlbum = Album(
    id: 'al1',
    name: 'Abbey Road',
    artists: [testArtist],
    releaseDate: '1969',
    externalUri: '',
    totalTracks: 17,
    albumType: AlbumType.album,
  );

  setUp(() async {
    await sl.reset();

    mockEngine = MockPluginEngine();
    mockMetadata = MockMetadataPlugin();
    mockArtist = MockArtistService();
    mockPlayerCubit = MockPlayerCubit();

    when(() => mockPlayerCubit.state).thenReturn(const PlayerState());
    when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());

    sl.registerLazySingleton<MetadataPluginEngine>(() => mockEngine);
    sl.registerLazySingleton<NoticeBus>(() => NoticeBus());
  sl.registerLazySingleton<MediaRepository>(() => MediaRepository(mockEngine));

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.artist).thenReturn(mockArtist);

    final mockAuth = MockAuthService();
    when(() => mockMetadata.auth).thenReturn(mockAuth);
    when(() => mockAuth.isAuthenticated()).thenAnswer((_) async => false);
    sl.registerLazySingleton<UserCubit>(() => TestUserCubit(testUserState()));
  });

  Widget buildTestableWidget({Artist? artist}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<PlayerCubit>.value(value: mockPlayerCubit),
          BlocProvider<UserCubit>.value(value: sl<UserCubit>()),
        ],
        child: ArtistPage(artist: artist ?? testArtist),
      ),
    );
  }

  void stubArtistSections() {
    when(
      () => mockArtist.getArtist('a1'),
    ).thenAnswer((_) async => testArtist);
    when(() => mockArtist.topTracks('a1', offset: 0, limit: 6)).thenAnswer(
      (_) async => PaginatedResult(
        items: [testTrack],
        total: 1,
        offset: 0,
        limit: 6,
      ),
    );
    when(() => mockArtist.albums('a1', offset: 0, limit: 6)).thenAnswer(
      (_) async => PaginatedResult(
        items: [testAlbum],
        total: 1,
        offset: 0,
        limit: 6,
      ),
    );
    when(() => mockArtist.related('a1', offset: 0, limit: 6)).thenAnswer(
      (_) async => PaginatedResult(
        items: [testArtist],
        total: 1,
        offset: 0,
        limit: 6,
      ),
    );
  }

  group('ArtistPage Widget Tests', () {
    testWidgets(
      'renders artist header, TrackMatrix popular tracks, discography and related sections',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2000);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        when(
          () => mockArtist.getArtist('a1'),
        ).thenAnswer((_) async => testArtist);
        when(() => mockArtist.topTracks('a1', offset: 0, limit: 6)).thenAnswer(
          (_) async => PaginatedResult(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 6,
          ),
        );
        when(() => mockArtist.albums('a1', offset: 0, limit: 6)).thenAnswer(
          (_) async => PaginatedResult(
            items: [testAlbum],
            total: 1,
            offset: 0,
            limit: 6,
          ),
        );
        when(() => mockArtist.related('a1', offset: 0, limit: 6)).thenAnswer(
          (_) async => PaginatedResult(
            items: [testArtist],
            total: 1,
            offset: 0,
            limit: 6,
          ),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('The Beatles'), findsWidgets);
        expect(find.text('Popular Tracks'), findsOneWidget);
        expect(find.byType(TrackMatrix), findsOneWidget);
        expect(find.text('Yesterday'), findsOneWidget);
        expect(find.text('Discography'), findsOneWidget);
        expect(find.text('Abbey Road'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Fans Also Like'),
          300.0,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Fans Also Like'), findsOneWidget);
      },
    );

    testWidgets('renders ErrorCard when all sections fail', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      when(
        () => mockArtist.getArtist('a1'),
      ).thenAnswer((_) async => throw Exception('API error'));
      when(
        () => mockArtist.topTracks('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => throw Exception('API error'));
      when(
        () => mockArtist.albums('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => throw Exception('API error'));
      when(
        () => mockArtist.related('a1', offset: 0, limit: 6),
      ).thenAnswer((_) async => throw Exception('API error'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('An unexpected error occurred: API error'),
        findsOneWidget,
      );
    });

    testWidgets('header options queue all top tracks', (tester) async {
      final second = Track(
        id: 't2',
        name: 'Come Together',
        externalUri: '',
        artists: testTrack.artists,
        album: testTrack.album,
        durationMs: 259000,
      );
      when(
        () => mockArtist.getArtist('a1'),
      ).thenAnswer((_) async => testArtist);
      when(() => mockArtist.topTracks('a1', offset: 0, limit: 6)).thenAnswer(
        (_) async => PaginatedResult(
          items: [testTrack],
          total: 1,
          offset: 0,
          limit: 6,
        ),
      );
      when(() => mockArtist.topTracks('a1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult(
          items: [testTrack, second],
          total: 2,
          offset: 0,
          limit: 20,
        ),
      );
      when(() => mockArtist.albums('a1', offset: 0, limit: 6)).thenAnswer(
        (_) async => PaginatedResult(
          items: const [],
          total: 0,
          offset: 0,
          limit: 6,
        ),
      );
      when(() => mockArtist.related('a1', offset: 0, limit: 6)).thenAnswer(
        (_) async => PaginatedResult(
          items: const [],
          total: 0,
          offset: 0,
          limit: 6,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Play Next'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);

      await tester.tap(find.text('Add to Queue'));
      await tester.pumpAndSettle();

      verify(
        () => mockPlayerCubit.addAllToQueue([testTrack, second]),
      ).called(1);
    });

    testWidgets('hides the heart while the saved index is unknown',
        (tester) async {
      stubArtistSections();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('shows an empty heart for a loaded but unsaved artist',
        (tester) async {
      stubArtistSections();
      (sl<UserCubit>() as TestUserCubit).set(
        testUserState(loaded: {MediaItemType.artist}),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('shows a full heart for a saved artist', (tester) async {
      stubArtistSections();
      (sl<UserCubit>() as TestUserCubit).set(
        testUserState(
          loaded: {MediaItemType.artist},
          artistIds: {'a1'},
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('reloads the index once when it is unknown', (tester) async {
      stubArtistSections();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(
        (sl<UserCubit>() as TestUserCubit).refreshed,
        [MediaItemType.artist],
      );
    });

    testWidgets('does not reload the index when it is known', (tester) async {
      stubArtistSections();
      (sl<UserCubit>() as TestUserCubit).set(
        testUserState(loaded: {MediaItemType.artist}),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect((sl<UserCubit>() as TestUserCubit).refreshed, isEmpty);
    });

    testWidgets('a credit without MBID shows an empty heart it cannot save',
        (tester) async {
      const ghost = Artist(id: '', name: 'Ghost Singer', externalUri: '');
      when(
        () => mockArtist.getArtist(''),
      ).thenAnswer((_) async => throw Exception('API error'));
      when(() => mockArtist.topTracks('', offset: 0, limit: 6)).thenAnswer(
        (_) async => const PaginatedResult<Track>(
          items: [],
          total: 0,
          offset: 0,
          limit: 6,
        ),
      );
      when(() => mockArtist.albums('', offset: 0, limit: 6)).thenAnswer(
        (_) async => const PaginatedResult<Album>(
          items: [],
          total: 0,
          offset: 0,
          limit: 6,
        ),
      );
      when(() => mockArtist.related('', offset: 0, limit: 6)).thenAnswer(
        (_) async => const PaginatedResult<Artist>(
          items: [],
          total: 0,
          offset: 0,
          limit: 6,
        ),
      );
      (sl<UserCubit>() as TestUserCubit).set(
        testUserState(loaded: {MediaItemType.artist}),
      );

      await tester.pumpWidget(buildTestableWidget(artist: ghost));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });
  });
}
