import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
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

      cubit = PlaylistCubit(mockPluginEngine);
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

    test('toggleSave updates isSaved state in PlaylistLoadedState', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.playlist).thenReturn(mockPlaylistService);
      when(() => mockPlaylistService.save('pl1')).thenAnswer((_) async {});

      cubit.emit(
        PlaylistLoadedState(
          playlist: testPlaylist,
          tracks: PaginatedResult<Track>(
            items: [],
            total: 0,
            offset: 0,
            limit: 20,
          ),
          isSaved: false,
        ),
      );

      await cubit.toggleSave();

      expect(cubit.state, isA<PlaylistLoadedState>());
      expect((cubit.state as PlaylistLoadedState).isSaved, isTrue);
      verify(() => mockPlaylistService.save('pl1')).called(1);
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
  });
}
