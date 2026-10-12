import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockPlaylistService extends Mock implements IPlaylist {}

void main() {
  group('PlaylistCubit Unit Tests', () {
    late MockPluginEngine mockPluginEngine;
    late MockMetadataPlugin mockMetadataPlugin;
    late MockPlaylistService mockPlaylistService;
    late NoticeBus noticeBus;
    late TestUserCubit savedMedia;
    late PlaylistCubit cubit;

    final testPlaylist = Playlist(
      id: 'pl1',
      name: 'Test Playlist',
      description: 'Desc',
      externalUri: '',
      owner: User(id: 'u1', name: 'Dan', externalUri: ''),
    );

    final testTrack = Track(
      id: 't1',
      name: 'Test Track',
      externalUri: '',
      artists: [Artist(id: 'a1', name: 'Test Artist', externalUri: '')],
      album: Album(
        id: 'al1',
        name: 'Test Album',
        artists: [],
        releaseDate: '',
        externalUri: '',
        totalTracks: 1,
        albumType: AlbumType.album,
      ),
      durationMs: 180000,
    );

    setUp(() {
      mockPluginEngine = MockPluginEngine();
      mockMetadataPlugin = MockMetadataPlugin();
      mockPlaylistService = MockPlaylistService();

      noticeBus = NoticeBus();
      savedMedia = TestUserCubit(testUserState());
      cubit = PlaylistCubit(
        MediaRepository(mockPluginEngine),
        PlaylistRepository(mockPluginEngine),
        noticeBus,
        savedMedia: savedMedia,
        edits: savedMedia,
      );
    });

    tearDown(() async {
      await cubit.close();
      await savedMedia.close();
    });

    test('initial state is PlaylistInitialState', () {
      expect(cubit.state, isA<PlaylistInitialState>());
    });

    test('loadPlaylist emits ErrorState when hasMetadata is false', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(false);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PlaylistErrorState>().having(
            (s) => s.error,
            'error',
            isA<PluginNotLoadedException>(),
          ),
        ]),
      );

      await cubit.loadPlaylist(testPlaylist);
    });

    test('loadPlaylist fetches playlist tracks successfully', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);

      when(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [testTrack],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PlaylistLoadingState>(),
          isA<PlaylistLoadedState>()
              .having((s) => s.tracks.items.length, 'tracks length', 1)
              .having(
                (s) => s.tracks.items.first.name,
                'track name',
                'Test Track',
              ),
        ]),
      );

      await cubit.loadPlaylist(testPlaylist);
    });

    test(
      'loadMoreTracks appends newly fetched tracks to current tracks',
      () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);

        when(
          () => mockPlaylistService.tracks('pl1', offset: 1, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [
              Track(
                id: 't2',
                name: 'Track 2',
                externalUri: '',
                artists: [],
                album: testTrack.album,
                durationMs: 120000,
              ),
            ],
            total: 2,
            offset: 1,
            limit: 20,
          ),
        );

        cubit.emit(
          PlaylistLoadedState(
            playlist: testPlaylist,
            tracks: PaginatedResult<Track>(
              items: [testTrack],
              total: 2,
              offset: 0,
              limit: 20,
            ),
          ),
        );

        await cubit.loadMoreTracks();

        final state = cubit.state as PlaylistLoadedState;
        expect(state.tracks.items.length, equals(2));
        expect(state.tracks.items.last.name, equals('Track 2'));
        expect(state.hasMoreTracks, isFalse);
      },
    );

    test(
      'loadMoreTracks emits PlaylistLoadMoreErrorState on failure',
      () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);

        when(
          () => mockPlaylistService.tracks('pl1', offset: 1, limit: 20),
        ).thenThrow(Exception('Pagination network timeout'));

        cubit.emit(
          PlaylistLoadedState(
            playlist: testPlaylist,
            tracks: PaginatedResult<Track>(
              items: [testTrack],
              total: 2,
              offset: 0,
              limit: 20,
            ),
          ),
        );

        await cubit.loadMoreTracks();

        expect(cubit.state, isA<PlaylistLoadMoreErrorState>());
        final errorState = cubit.state as PlaylistLoadMoreErrorState;
        expect(errorState.tracks.items.length, equals(1));
      },
    );

    test('a section fetch emits a notice when it needs one', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      final error = const MetadataAuthRequiredException('sign in');
      when(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer((_) async => throw error);

      final notices = <Object>[];
      final subscription = noticeBus.notices.listen(notices.add);
      await cubit.loadPlaylist(testPlaylist);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<PlaylistErrorState>());
      expect(notices, hasLength(1));
      expect((notices.single as ErrorNotice).error, same(error));
      await subscription.cancel();
    });

    test('a section fetch stays silent for non-notifiable errors', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      when(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer((_) async => throw Exception('network'));

      final notices = <Object>[];
      final subscription = noticeBus.notices.listen(notices.add);
      await cubit.loadPlaylist(testPlaylist);
      await Future<void>.delayed(Duration.zero);

      expect(notices, isEmpty);
      await subscription.cancel();
    });

    test('removeTrack drops the track and delegates the removal', () async {
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        ),
      );

      final removed = await cubit.removeTrack(testTrack);

      expect(removed, isTrue);
      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items, isEmpty);
      expect(state.tracks.total, 0);
      expect(savedMedia.removedTracks, [('pl1', 't1')]);
    });

    test('removeTrack restores the track when the write fails', () async {
      savedMedia.nextRemoveResult = false;
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        ),
      );

      final removed = await cubit.removeTrack(testTrack);

      expect(removed, isFalse);
      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items, hasLength(1));
      expect(state.tracks.total, 1);
    });

    test('deletePlaylist calls the repository and reports success', () async {
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      when(
        () => mockPlaylistService.deletePlaylist('pl1'),
      ).thenAnswer((_) async {});

      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        ),
      );

      final deleted = await cubit.deletePlaylist();

      expect(deleted, isTrue);
      verify(() => mockPlaylistService.deletePlaylist('pl1')).called(1);
    });

    test(
      'deletePlaylist notifies and reports failure when the write fails',
      () async {
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
        final error = Exception('delete failed');
        when(
          () => mockPlaylistService.deletePlaylist('pl1'),
        ).thenAnswer((_) async => throw error);

        cubit.emit(
          PlaylistLoadedState(
            playlist: testPlaylist,
            tracks: PaginatedResult<Track>(
              items: [testTrack],
              total: 1,
              offset: 0,
              limit: 20,
            ),
          ),
        );

        final notices = <Object>[];
        final subscription = noticeBus.notices.listen(notices.add);
        final deleted = await cubit.deletePlaylist();
        await Future<void>.delayed(Duration.zero);

        expect(deleted, isFalse);
        expect((notices.single as ErrorNotice).error, same(error));
        await subscription.cancel();
      },
    );

    test('an external add refetches the loaded window', () async {
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        ),
      );
      final added = Track(
        id: 't2',
        name: 'New Song',
        externalUri: '',
        artists: const [],
        album: testTrack.album,
        durationMs: 120000,
      );
      when(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [testTrack, added],
          total: 2,
          offset: 0,
          limit: 20,
        ),
      );

      savedMedia.pushEdits(const PlaylistTracksChanged('pl1', added: ['t2']));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items.map((track) => track.id), ['t1', 't2']);
      expect(state.tracks.total, 2);
      verify(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
      ).called(1);
    });

    test('an external removal refetches the loaded window', () async {
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      final second = Track(
        id: 't2',
        name: 'Second Song',
        externalUri: '',
        artists: const [],
        album: testTrack.album,
        durationMs: 120000,
      );
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [testTrack, second],
            total: 2,
            offset: 0,
            limit: 20,
          ),
        ),
      );
      when(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [second],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );

      savedMedia.pushEdits(const PlaylistTracksChanged('pl1', removed: ['t1']));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items.map((track) => track.id), ['t2']);
      expect(state.tracks.total, 1);
    });

    test('its own removal event is ignored', () async {
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        ),
      );

      // The track is already gone locally (the swipe applied it): the own
      // event must not trigger a refetch.
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: const PaginatedResult<Track>(
            items: [],
            total: 0,
            offset: 0,
            limit: 20,
          ),
        ),
      );
      savedMedia.pushEdits(const PlaylistTracksChanged('pl1', removed: ['t1']));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      verifyNever(
        () => mockPlaylistService.tracks(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      );
      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items, isEmpty);
    });

    test('events for other playlists are ignored', () async {
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        ),
      );

      savedMedia.pushEdits(
        const PlaylistTracksChanged('pl-other', added: ['t9']),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1));

      verifyNever(
        () => mockPlaylistService.tracks(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      );
      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items.map((track) => track.id), ['t1']);
    });

    test('a failed refetch keeps the state', () async {
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        ),
      );
      when(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
      ).thenAnswer((_) async => throw Exception('offline'));

      savedMedia.pushEdits(const PlaylistTracksChanged('pl1', added: ['t2']));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items.map((track) => track.id), ['t1']);
      expect(state.tracks.total, 1);
    });

    test('the refetch keeps the loaded window size', () async {
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      final loaded = List.generate(
        25,
        (i) => Track(
          id: 't$i',
          name: 'Song $i',
          externalUri: '',
          artists: const [],
          album: testTrack.album,
          durationMs: 1000,
        ),
      );
      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: loaded,
            total: 30,
            offset: 0,
            limit: 25,
          ),
        ),
      );
      when(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 25),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: loaded,
          total: 26,
          offset: 0,
          limit: 25,
        ),
      );

      savedMedia.pushEdits(const PlaylistTracksChanged('pl1', added: ['t99']));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      verify(
        () => mockPlaylistService.tracks('pl1', offset: 0, limit: 25),
      ).called(1);
      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items, hasLength(25));
    });

    group('pendingSource', () {
      test('returns null when nothing is loaded', () {
        expect(cubit.pendingSource(), isNull);
      });

      test('returns a source bound to the loaded window', () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
        when(
          () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [testTrack],
            total: 3,
            offset: 0,
            limit: 20,
          ),
        );
        when(
          () => mockPlaylistService.tracks('pl1', offset: 1, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [testTrack],
            total: 3,
            offset: 1,
            limit: 20,
          ),
        );

        await cubit.loadPlaylist(testPlaylist);

        final source = cubit.pendingSource();
        expect(source, isNotNull);
        final pending = source!;
        expect(pending.nextOffset, equals(1));
        expect(pending.total, equals(3));

        final page = await pending.loader(pending.nextOffset);
        expect(page.items, hasLength(1));
        verify(
          () => mockPlaylistService.tracks('pl1', offset: 1, limit: 20),
        ).called(1);
      });

      test('returns null when the list is complete', () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
        when(
          () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [testTrack],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        );

        await cubit.loadPlaylist(testPlaylist);

        expect(cubit.pendingSource(), isNull);
      });
    });
    group('loadAllTracks', () {
      Track song(String id, String name) => Track(
        id: id,
        name: name,
        externalUri: '',
        artists: testTrack.artists,
        album: testTrack.album,
        durationMs: 1000,
      );

      Future<void> wireEngine() async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      }

      test('reads every page in order', () async {
        await wireEngine();
        when(
          () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [song('t1', 'Song 1')],
            total: 3,
            offset: 0,
            limit: 20,
          ),
        );
        when(
          () => mockPlaylistService.tracks('pl1', offset: 1, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [song('t2', 'Song 2'), song('t3', 'Song 3')],
            total: 3,
            offset: 1,
            limit: 20,
          ),
        );

        await cubit.loadPlaylist(testPlaylist);
        final all = await cubit.loadAllTracks();

        expect(all?.map((t) => t.id), ['t1', 't2', 't3']);
      });

      test('rethrows a page failure without notifying', () async {
        await wireEngine();
        when(
          () => mockPlaylistService.tracks('pl1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [song('t1', 'Song 1')],
            total: 2,
            offset: 0,
            limit: 20,
          ),
        );
        when(
          () => mockPlaylistService.tracks('pl1', offset: 1, limit: 20),
        ).thenThrow(const PendingLoadException('boom'));

        await cubit.loadPlaylist(testPlaylist);
        final notices = <Object>[];
        final subscription = noticeBus.notices.listen(notices.add);
        Object? caught;
        try {
          await cubit.loadAllTracks();
        } catch (e) {
          caught = e;
        }
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();

        expect(caught, isA<PendingLoadException>());
        expect(notices, isEmpty);
      });

      test('returns null when nothing is loaded', () async {
        expect(await cubit.loadAllTracks(), isNull);
      });
    });
  });
}
