import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_cubit.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockAlbumService extends Mock implements IAlbum {}

void main() {
  group('AlbumCubit Unit Tests', () {
    late MockPluginEngine mockPluginEngine;
    late MockMetadataPlugin mockMetadataPlugin;
    late MockAlbumService mockAlbumService;
    late NoticeBus noticeBus;
    late AlbumCubit cubit;

    final testAlbum = Album(
      id: 'al1',
      name: 'Abbey Road',
      artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
      releaseDate: '1969',
      externalUri: '',
      totalTracks: 17,
      albumType: AlbumType.album,
    );

    Track createTrack(String id, String name) {
      return Track(
        id: id,
        name: name,
        externalUri: '',
        artists: testAlbum.artists,
        album: testAlbum,
        durationMs: 180000,
      );
    }

    setUp(() {
      mockPluginEngine = MockPluginEngine();
      mockMetadataPlugin = MockMetadataPlugin();
      mockAlbumService = MockAlbumService();

      noticeBus = NoticeBus();
      cubit = AlbumCubit(mockPluginEngine, noticeBus);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is AlbumInitialState', () {
      expect(cubit.state, isA<AlbumInitialState>());
    });

    test('loadAlbum emits ErrorState when hasMetadata is false', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(false);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AlbumErrorState>().having(
            (s) => s.error,
            'error',
            isA<PluginNotLoadedException>(),
          ),
        ]),
      );

      await cubit.loadAlbum(testAlbum);
    });

    test(
      'loadAlbum fetches album tracks and computes hasMoreTracks correctly',
      () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);

        when(
          () => mockAlbumService.getAlbum('al1'),
        ).thenAnswer((_) async => testAlbum);

        when(
          () => mockAlbumService.tracks('al1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [
              createTrack('t1', 'Come Together'),
              createTrack('t2', 'Something'),
            ],
            total: 17,
            offset: 0,
            limit: 20,
          ),
        );

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AlbumLoadingState>(),
            isA<AlbumLoadedState>()
                .having((s) => s.tracks.items.length, 'loaded count', 2)
                .having((s) => s.tracks.total, 'total tracks', 17)
                .having((s) => s.hasMoreTracks, 'hasMoreTracks', isTrue),
          ]),
        );

        await cubit.loadAlbum(testAlbum);
      },
    );

    test(
      'loadMoreTracks appends new page items and updates pagination state',
      () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);

        when(
          () => mockAlbumService.getAlbum('al1'),
        ).thenAnswer((_) async => testAlbum);

        when(
          () => mockAlbumService.tracks('al1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [createTrack('t1', 'Track 1'), createTrack('t2', 'Track 2')],
            total: 3,
            offset: 0,
            limit: 20,
          ),
        );

        when(
          () => mockAlbumService.tracks('al1', offset: 2, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [createTrack('t3', 'Track 3')],
            total: 3,
            offset: 2,
            limit: 20,
          ),
        );

        await cubit.loadAlbum(testAlbum);
        expect((cubit.state as AlbumLoadedState).hasMoreTracks, isTrue);

        await cubit.loadMoreTracks();

        expect(cubit.state, isA<AlbumLoadedState>());
        final loadedState = cubit.state as AlbumLoadedState;
        expect(loadedState.tracks.items.length, equals(3));
        expect(loadedState.hasMoreTracks, isFalse);
      },
    );

    test('toggleSave updates isSaved state', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);
      when(() => mockAlbumService.save(['al1'])).thenAnswer((_) async {});

      cubit.emit(
        AlbumLoadedState(
          album: testAlbum,
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

      expect(cubit.state, isA<AlbumLoadedState>());
      expect((cubit.state as AlbumLoadedState).isSaved, isTrue);
      verify(() => mockAlbumService.save(['al1'])).called(1);
    });

    test('toggleSave emits a notice when the plugin rejects', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);
      final error = const MetadataAuthRequiredException('sign in');
      when(() => mockAlbumService.save(['al1'])).thenAnswer((_) async {
        throw error;
      });

      cubit.emit(
        AlbumLoadedState(
          album: testAlbum,
          tracks: PaginatedResult<Track>(
            items: [],
            total: 0,
            offset: 0,
            limit: 20,
          ),
          isSaved: false,
        ),
      );

      final notices = <Object>[];
      final subscription = noticeBus.notices.listen(notices.add);
      await cubit.toggleSave();
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as AlbumLoadedState).isSaved, isFalse);
      expect(notices, hasLength(1));
      expect(notices.single, same(error));
      await subscription.cancel();
    });

    test('a section fetch emits a notice when it needs one', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);
      final error = const MetadataAuthRequiredException('sign in');
      when(
        () => mockAlbumService.tracks('al1', offset: 0, limit: 20),
      ).thenAnswer((_) async => throw error);

      final notices = <Object>[];
      final subscription = noticeBus.notices.listen(notices.add);
      await cubit.loadAlbum(testAlbum);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<AlbumErrorState>());
      expect(notices, hasLength(1));
      expect(notices.single, same(error));
      await subscription.cancel();
    });

    test('a section fetch stays silent for non-notifiable errors', () async {
      when(() => mockPluginEngine.hasMetadata).thenReturn(true);
      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);
      when(
        () => mockAlbumService.tracks('al1', offset: 0, limit: 20),
      ).thenAnswer((_) async => throw Exception('network'));

      final notices = <Object>[];
      final subscription = noticeBus.notices.listen(notices.add);
      await cubit.loadAlbum(testAlbum);
      await Future<void>.delayed(Duration.zero);

      expect(notices, isEmpty);
      await subscription.cancel();
    });
  });
}
