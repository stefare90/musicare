import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockPlaylistService extends Mock implements IPlaylist {}

void main() {
  group('PlaylistCubit Unit Tests', () {
    late MockPluginEngine mockPluginEngine;
    late MockMetadataPlugin mockMetadataPlugin;
    late MockPlaylistService mockPlaylistService;
    late NoticeBus noticeBus;
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
      cubit = PlaylistCubit(
        MediaRepository(mockPluginEngine),
        PlaylistRepository(mockPluginEngine),
        noticeBus,
      );
    });

    tearDown(() {
      cubit.close();
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
      expect(notices.single, same(error));
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

    test('removeTrack drops the track and writes the removal', () async {
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      when(
        () => mockPlaylistService.removeTracks('pl1', ['t1']),
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

      final removed = await cubit.removeTrack(testTrack);

      expect(removed, isTrue);
      final state = cubit.state as PlaylistLoadedState;
      expect(state.tracks.items, isEmpty);
      expect(state.tracks.total, 0);
      verify(() => mockPlaylistService.removeTracks('pl1', ['t1'])).called(1);
    });

    test(
      'removeTrack restores the track and notifies when the write fails',
      () async {
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
        final error = Exception('write failed');
        when(
          () => mockPlaylistService.removeTracks('pl1', ['t1']),
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
        final removed = await cubit.removeTrack(testTrack);
        await Future<void>.delayed(Duration.zero);

        expect(removed, isFalse);
        final state = cubit.state as PlaylistLoadedState;
        expect(state.tracks.items, hasLength(1));
        expect(state.tracks.total, 1);
        expect(notices.single, same(error));
        await subscription.cancel();
      },
    );

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

    test('deletePlaylist notifies and reports failure when the write fails', () async {
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
      expect(notices.single, same(error));
      await subscription.cancel();
    });
  });
}
