import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/details/playlist/presentation/pages/playlist_page.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockPlaylistService extends Mock implements IPlaylist {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

class MockAuthService extends Mock implements IAuth {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine mockEngine;
  late MockMetadataPlugin mockMetadata;
  late MockPlaylistService mockPlaylist;
  late MockPlayerCubit mockPlayerCubit;
  late TestUserCubit userCubit;

  final testPlaylist = Playlist(
    id: 'pl1',
    name: 'Top 50 Hits',
    description: 'Best songs',
    externalUri: '',
    owner: User(id: 'u1', name: 'Spotify', externalUri: ''),
  );

  final testTrack = Track(
    id: 't1',
    name: 'Song A',
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
    album: Album(
      id: 'al1',
      name: 'Album',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    ),
    durationMs: 180000,
  );

  setUp(() async {
    await sl.reset();

    mockEngine = MockPluginEngine();
    mockMetadata = MockMetadataPlugin();
    mockPlaylist = MockPlaylistService();
    mockPlayerCubit = MockPlayerCubit();

    when(() => mockPlayerCubit.state).thenReturn(const PlayerState());
    when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());

    sl.registerLazySingleton<MetadataPluginEngine>(() => mockEngine);
    sl.registerLazySingleton<NoticeBus>(() => NoticeBus());
    sl.registerLazySingleton<MediaRepository>(
      () => MediaRepository(mockEngine),
    );
    sl.registerLazySingleton<PlaylistRepository>(
      () => PlaylistRepository(mockEngine),
    );
    userCubit = TestUserCubit(
      testUserState(isAuthenticated: true, userId: 'me'),
    );
    sl.registerLazySingleton<UserCubit>(() => userCubit);
    sl.registerLazySingleton<UserSavedMediaIndex>(() => userCubit);
    sl.registerLazySingleton<UserPlaylistEdits>(() => userCubit);

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.playlist).thenReturn(mockPlaylist);

    final mockAuth = MockAuthService();
    when(() => mockMetadata.auth).thenReturn(mockAuth);
    when(() => mockAuth.isAuthenticated()).thenAnswer((_) async => false);

  });

  Widget buildTestableWidget({
    MetadataPluginCubit? metadataCubit,
    Playlist? playlist,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              PlaylistPage(playlist: playlist ?? testPlaylist),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) =>
              const Scaffold(body: Text('Library Page')),
        ),
      ],
    );
    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => NoticeListener(
        notices: sl<NoticeBus>().notices,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PlayerCubit>.value(value: mockPlayerCubit),
            BlocProvider<MetadataPluginCubit>.value(
              value: metadataCubit ?? buildMockMetadataPluginCubit(),
            ),
            BlocProvider<UserCubit>.value(value: userCubit),
          ],
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  group('PlaylistPage Widget Tests', () {
    testWidgets('renders playlist header with title and owner', (tester) async {
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult(items: [], total: 0, offset: 0, limit: 20),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Top 50 Hits'), findsNWidgets(2)); // Header + AppBar
      expect(find.text('Spotify'), findsOneWidget);
    });

    testWidgets('shows Public for an owned public playlist', (tester) async {
      userCubit.set(testUserState(isAuthenticated: true, userId: 'u1'));
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult(items: [], total: 0, offset: 0, limit: 20),
      );
      final publicPlaylist = Playlist(
        id: 'pl1',
        name: 'Top 50 Hits',
        description: 'Best songs',
        externalUri: '',
        owner: User(id: 'u1', name: 'Spotify', externalUri: ''),
        isPublic: true,
      );

      await tester.pumpWidget(buildTestableWidget(playlist: publicPlaylist));
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private'), findsNothing);
    });

    testWidgets('shows Private for an owned private playlist', (tester) async {
      userCubit.set(testUserState(isAuthenticated: true, userId: 'u1'));
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult(items: [], total: 0, offset: 0, limit: 20),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Private'), findsOneWidget);
      expect(find.text('Public'), findsNothing);
    });

    testWidgets('shows no visibility for a playlist owned by someone else', (
      tester,
    ) async {
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult(items: [], total: 0, offset: 0, limit: 20),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsNothing);
      expect(find.text('Private'), findsNothing);
    });

    testWidgets('announces the sign-in invitation when access is required', (
      tester,
    ) async {
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => throw const MetadataAuthRequiredException('sign in'),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Metadata sign-in required.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('swiping a track asks for confirmation and removes it', (
      tester,
    ) async {
      userCubit.set(testUserState(isAuthenticated: true, userId: 'u1'));
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [testTrack],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );
      when(
        () => mockPlaylist.removeTracks('pl1', ['t1']),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.drag(find.text('Song A'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Remove from playlist?'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(userCubit.removedTracks, [('pl1', 't1')]);
      expect(find.text('Removed from Top 50 Hits'), findsOneWidget);
    });

    testWidgets('cancelling the removal keeps the track', (tester) async {
      userCubit.set(testUserState(isAuthenticated: true, userId: 'u1'));
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [testTrack],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.drag(find.text('Song A'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockPlaylist.removeTracks(any(), any()));
      expect(find.text('Song A'), findsOneWidget);
    });

    testWidgets(
      'a playlist owned by someone else does not allow removing tracks',
      (tester) async {
        when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.byType(Dismissible), findsNothing);

        await tester.drag(find.text('Song A'), const Offset(-500, 0));
        await tester.pumpAndSettle();

        verifyNever(() => mockPlaylist.removeTracks(any(), any()));
        expect(find.text('Song A'), findsOneWidget);
      },
    );

    testWidgets(
      'an owned playlist offers delete, confirms and returns to the library',
      (tester) async {
        userCubit.set(testUserState(isAuthenticated: true, userId: 'u1'));
        when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        );
        when(() => mockPlaylist.deletePlaylist('pl1')).thenAnswer((_) async {});

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Delete Playlist'), findsOneWidget);
        expect(find.text('Save Playlist'), findsNothing);

        await tester.tap(find.text('Delete Playlist'));
        await tester.pumpAndSettle();
        expect(find.text('Delete playlist?'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Delete Playlist'),
        );
        await tester.pumpAndSettle();

        verify(() => mockPlaylist.deletePlaylist('pl1')).called(1);
        expect(find.text('Library Page'), findsOneWidget);
      },
    );

    testWidgets('cancelling the delete keeps the playlist', (tester) async {
      userCubit.set(testUserState(isAuthenticated: true, userId: 'u1'));
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [testTrack],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Playlist'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockPlaylist.deletePlaylist(any()));
      expect(find.text('Top 50 Hits'), findsNWidgets(2));
    });

    testWidgets('a playlist owned by someone else offers save, not delete', (
      tester,
    ) async {
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [testTrack],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Save Playlist'), findsOneWidget);
      expect(find.text('Delete Playlist'), findsNothing);
    });

    testWidgets('an external add updates the list without moving it', (
      tester,
    ) async {
      Track song(int i) => Track(
        id: 't$i',
        name: 'Song $i',
        externalUri: '',
        artists: const [],
        album: testTrack.album,
        durationMs: 1000,
      );
      final loaded = List.generate(3, song);
      when(
        () => mockPlaylist.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: loaded,
          total: 3,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();
      expect(find.text('Song 2'), findsOneWidget);

      when(
        () => mockPlaylist.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [...loaded, song(3)],
          total: 4,
          offset: 0,
          limit: 20,
        ),
      );
      userCubit.pushEdits(const PlaylistTracksChanged('pl1', added: ['t3']));
      await tester.pumpAndSettle();

      expect(find.text('Song 3'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Song 0')).dy,
        lessThan(tester.getTopLeft(find.text('Song 3')).dy),
      );
    });

    testWidgets('an external add keeps the scroll position', (tester) async {
      Track song(int i) => Track(
        id: 't$i',
        name: 'Song $i',
        externalUri: '',
        artists: const [],
        album: testTrack.album,
        durationMs: 1000,
      );
      final window = List.generate(25, song).sublist(0, 20);
      when(
        () => mockPlaylist.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: window,
          total: 25,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Scroll until the head is off-screen (the header absorbs part of the
      // gesture).
      for (
        var i = 0;
        i < 5 && find.text('Song 0').evaluate().isNotEmpty;
        i++
      ) {
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Song 0'), findsNothing);
      final scrolled =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(scrolled.position.pixels, greaterThan(0));
      clearInteractions(mockPlaylist);

      // The provider appends at the tail, outside the loaded window.
      when(
        () => mockPlaylist.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: window,
          total: 26,
          offset: 0,
          limit: 20,
        ),
      );
      userCubit.pushEdits(const PlaylistTracksChanged('pl1', added: ['t99']));
      await tester.pumpAndSettle();

      verify(
        () => mockPlaylist.tracks('pl1', offset: 0, limit: 20),
      ).called(1);
      final settled =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(settled.position.pixels, scrolled.position.pixels);
      expect(find.text('Song 0'), findsNothing);
    });

    testWidgets('an external removal updates the list without moving it', (
      tester,
    ) async {
      Track song(int i) => Track(
        id: 't$i',
        name: 'Song $i',
        externalUri: '',
        artists: const [],
        album: testTrack.album,
        durationMs: 1000,
      );
      final window = List.generate(25, song).sublist(0, 20);
      when(
        () => mockPlaylist.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: window,
          total: 25,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      for (
        var i = 0;
        i < 5 && find.text('Song 0').evaluate().isNotEmpty;
        i++
      ) {
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Song 0'), findsNothing);
      final scrolled =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(scrolled.position.pixels, greaterThan(0));
      // Remove a row that is actually built, whatever the viewport shows.
      String? victim;
      for (var i = 1; i < 20; i++) {
        if (find.text('Song $i').evaluate().isNotEmpty) {
          victim = 't$i';
          break;
        }
      }
      expect(victim, isNotNull);
      clearInteractions(mockPlaylist);

      final remaining = window.where((track) => track.id != victim).toList();
      when(
        () => mockPlaylist.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: remaining,
          total: 24,
          offset: 0,
          limit: 20,
        ),
      );
      userCubit.pushEdits(PlaylistTracksChanged('pl1', removed: [victim!]));
      await tester.pumpAndSettle();

      expect(find.text('Song ${victim.substring(1)}'), findsNothing);
      final settled =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(settled.position.pixels, scrolled.position.pixels);
    });
  });
}
