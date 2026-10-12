import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
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
      cubit = AlbumCubit(MediaRepository(mockPluginEngine), noticeBus);
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
      expect((notices.single as ErrorNotice).error, same(error));
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

    group('pendingSource', () {
      test('returns null when nothing is loaded', () {
        expect(cubit.pendingSource(), isNull);
      });

      test('returns a source bound to the loaded window', () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);
        final first = createTrack('t1', 'Come Together');
        final second = createTrack('t2', 'Something');
        when(
          () => mockAlbumService.tracks('al1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [first],
            total: 2,
            offset: 0,
            limit: 20,
          ),
        );
        when(
          () => mockAlbumService.tracks('al1', offset: 1, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [second],
            total: 2,
            offset: 1,
            limit: 20,
          ),
        );

        await cubit.loadAlbum(testAlbum);

        final source = cubit.pendingSource();
        expect(source, isNotNull);
        final pending = source!;
        expect(pending.nextOffset, equals(1));
        expect(pending.total, equals(2));

        final page = await pending.loader(pending.nextOffset);
        expect(page.items.single.id, equals('t2'));
      });

      test('returns null when the list is complete', () async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);
        when(
          () => mockAlbumService.tracks('al1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [createTrack('t1', 'Come Together')],
            total: 1,
            offset: 0,
            limit: 20,
          ),
        );

        await cubit.loadAlbum(testAlbum);

        expect(cubit.pendingSource(), isNull);
      });
    });
    group('loadAllTracks', () {
      Future<void> wireEngine() async {
        when(() => mockPluginEngine.hasMetadata).thenReturn(true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.album).thenReturn(mockAlbumService);
        when(
          () => mockAlbumService.getAlbum('al1'),
        ).thenAnswer((_) async => testAlbum);
      }

      test('reads every page in order', () async {
        await wireEngine();
        when(
          () => mockAlbumService.tracks('al1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [createTrack('t1', 'Song 1')],
            total: 3,
            offset: 0,
            limit: 20,
          ),
        );
        when(
          () => mockAlbumService.tracks('al1', offset: 1, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [createTrack('t2', 'Song 2'), createTrack('t3', 'Song 3')],
            total: 3,
            offset: 1,
            limit: 20,
          ),
        );

        await cubit.loadAlbum(testAlbum);
        final all = await cubit.loadAllTracks();

        expect(all?.map((t) => t.id), ['t1', 't2', 't3']);
      });

      test('rethrows a page failure without notifying', () async {
        await wireEngine();
        when(
          () => mockAlbumService.tracks('al1', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => PaginatedResult<Track>(
            items: [createTrack('t1', 'Song 1')],
            total: 2,
            offset: 0,
            limit: 20,
          ),
        );
        when(
          () => mockAlbumService.tracks('al1', offset: 1, limit: 20),
        ).thenThrow(const PendingLoadException('boom'));

        await cubit.loadAlbum(testAlbum);
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
