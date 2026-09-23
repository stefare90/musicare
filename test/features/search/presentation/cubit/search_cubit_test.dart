import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';

class MockMetadataPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockISearch extends Mock implements ISearch {}

void main() {
  group('SearchCubit Unit Tests', () {
    late MockMetadataPluginEngine mockEngine;
    late MockMetadataPlugin mockMetadata;
    late MockISearch mockSearch;
    late SearchCubit cubit;

    final dummyTrack = Track(
      id: 't1',
      name: 'Track 1',
      externalUri: '',
      artists: [],
      album: Album(
        id: 'al1',
        name: 'Album 1',
        artists: [],
        releaseDate: '',
        externalUri: '',
        totalTracks: 1,
        albumType: AlbumType.album,
      ),
      durationMs: 120000,
    );

    final dummyResponse = SearchResponse(
      tracks: [dummyTrack],
      albums: [],
      artists: [],
      playlists: [],
    );

    setUp(() {
      mockEngine = MockMetadataPluginEngine();
      mockMetadata = MockMetadataPlugin();
      mockSearch = MockISearch();

      when(() => mockEngine.hasMetadata).thenReturn(true);
      when(() => mockEngine.metadata).thenReturn(mockMetadata);
      when(() => mockMetadata.search).thenReturn(mockSearch);

      cubit = SearchCubit(
        mockEngine,
        debounceDuration: const Duration(milliseconds: 50),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('loadChips stores the typed subset declared by ISearch', () async {
      when(() => mockSearch.chips()).thenAnswer(
        (_) async => const [SearchCategory.tracks, SearchCategory.playlists],
      );

      await cubit.loadChips();

      expect(
        cubit.state.chips,
        equals(const [SearchCategory.tracks, SearchCategory.playlists]),
      );
      verify(() => mockSearch.chips()).called(1);
    });

    test('loadChips keeps an empty subset (aggregate-only plugin)', () async {
      when(() => mockSearch.chips()).thenAnswer((_) async => const []);

      await cubit.loadChips();

      expect(cubit.state.chips, isEmpty);
      expect(cubit.state.isAllCategory, isTrue);
    });

    test('loadChips falls back to every category when chips() throws', () async {
      when(
        () => mockSearch.chips(),
      ).thenAnswer((_) async => throw Exception('not implemented'));

      await cubit.loadChips();

      expect(cubit.state.chips, equals(SearchCategory.values));
    });

    test('loadChips is a no-op when no metadata plugin is loaded', () async {
      when(() => mockEngine.hasMetadata).thenReturn(false);

      await cubit.loadChips();

      expect(cubit.state.chips, isEmpty);
      verifyNever(() => mockSearch.chips());
    });

    test('onQueryChanged clears state if query is empty', () {
      cubit.onQueryChanged('   ');
      expect(cubit.state.query, equals('   '));
      expect(cubit.state.allResults, isNull);
      expect(cubit.state.isLoading, isFalse);
    });

    test('onQueryChanged debounces and triggers search', () async {
      when(() => mockSearch.all('coldplay')).thenAnswer(
        (_) async => dummyResponse,
      );

      cubit.onQueryChanged('coldplay');
      expect(cubit.state.query, equals('coldplay'));

      // Wait past debounce
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.allResults, equals(dummyResponse));
      verify(() => mockSearch.all('coldplay')).called(1);
    });

    test('search emits PluginNotLoadedException when hasMetadata is false', () async {
      when(() => mockEngine.hasMetadata).thenReturn(false);

      await cubit.search('query');

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isA<PluginNotLoadedException>());
    });

    test('selectChip updates category and executes search if query is present', () async {
      final paginatedTracks = PaginatedResult<Track>(
        items: [dummyTrack],
        total: 1,
        offset: 0,
        limit: 20,
      );

      when(
        () => mockSearch.tracks('rock', offset: 0, limit: any(named: 'limit')),
      ).thenAnswer((_) async => paginatedTracks);

      cubit.onQueryChanged('rock');
      await cubit.selectChip(SearchCategory.tracks);

      expect(cubit.state.selectedChip, equals(SearchCategory.tracks));
      expect(cubit.state.trackResults, equals(paginatedTracks));
    });

    test('selectChip(null) returns to the aggregate view', () async {
      when(
        () => mockSearch.tracks('rock', offset: 0, limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => const PaginatedResult<Track>(
          items: [],
          total: 0,
          offset: 0,
          limit: 20,
        ),
      );
      when(() => mockSearch.all('rock')).thenAnswer((_) async => dummyResponse);

      cubit.onQueryChanged('rock');
      await cubit.selectChip(SearchCategory.tracks);
      await cubit.selectChip(null);

      expect(cubit.state.selectedChip, isNull);
      expect(cubit.state.isAllCategory, isTrue);
      expect(cubit.state.allResults, equals(dummyResponse));
      verify(() => mockSearch.all('rock')).called(1);
    });

    test('loadMore fetches next page for active category', () async {
      final page1 = PaginatedResult<Track>(
        items: [dummyTrack],
        total: 2,
        offset: 0,
        limit: 1,
      );
      final dummyTrack2 = Track(
        id: 't2',
        name: 'Track 2',
        externalUri: '',
        artists: [],
        album: dummyTrack.album,
        durationMs: 150000,
      );
      final page2 = PaginatedResult<Track>(
        items: [dummyTrack2],
        total: 2,
        offset: 1,
        limit: 1,
      );

      when(
        () => mockSearch.tracks('rock', offset: 0, limit: 1),
      ).thenAnswer((_) async => page1);
      when(
        () => mockSearch.tracks('rock', offset: 1, limit: 1),
      ).thenAnswer((_) async => page2);

      final pagedCubit = SearchCubit(
        mockEngine,
        pageSize: 1,
      );

      await pagedCubit.selectChip(SearchCategory.tracks);
      await pagedCubit.search('rock');

      expect(pagedCubit.state.trackResults?.items.length, equals(1));
      expect(pagedCubit.state.hasMore, isTrue);

      await pagedCubit.loadMore();

      expect(pagedCubit.state.trackResults?.items.length, equals(2));
      expect(pagedCubit.state.trackResults?.items.last.id, equals('t2'));

      pagedCubit.close();
    });

    group('grid column pagination', () {
      List<Album> buildAlbums(int count) => List.generate(
            count,
            (i) => Album(
              id: 'al$i',
              name: 'Album $i',
              artists: const [],
              releaseDate: '2023',
              externalUri: '',
              totalTracks: 10,
              albumType: AlbumType.album,
            ),
          );

      test('updateGridColumns never emits a state', () async {
        final emissions = <SearchState>[];
        final subscription = cubit.stream.listen(emissions.add);

        cubit.updateGridColumns(2); // same as the default value
        cubit.updateGridColumns(3); // changed value, still no emit
        cubit.updateGridColumns(0); // invalid, ignored
        await Future<void>.delayed(Duration.zero);

        expect(emissions, isEmpty);
        await subscription.cancel();
      });

      test('grid categories request a limit rounded up to the columns',
          () async {
        for (final columns in [2, 3, 4]) {
          final gridCubit = SearchCubit(mockEngine, pageSize: 20);
          gridCubit.updateGridColumns(columns);
          final expected =
              MediaCardMetrics.pageSizeForColumns(20, columns);
          expect(expected % columns, 0);

          when(
            () => mockSearch.albums('rock', offset: 0, limit: expected),
          ).thenAnswer(
            (_) async => PaginatedResult<Album>(
              items: const [],
              total: 0,
              offset: 0,
              limit: expected,
            ),
          );
          when(
            () => mockSearch.artists('rock', offset: 0, limit: expected),
          ).thenAnswer(
            (_) async => const PaginatedResult<Artist>(
              items: [],
              total: 0,
              offset: 0,
              limit: 0,
            ),
          );
          when(
            () => mockSearch.playlists('rock', offset: 0, limit: expected),
          ).thenAnswer(
            (_) async => const PaginatedResult<Playlist>(
              items: [],
              total: 0,
              offset: 0,
              limit: 0,
            ),
          );

          gridCubit.onQueryChanged('rock');
          await gridCubit.selectChip(SearchCategory.albums);
          verify(
            () => mockSearch.albums('rock', offset: 0, limit: expected),
          ).called(1);

          await gridCubit.selectChip(SearchCategory.artists);
          verify(
            () => mockSearch.artists('rock', offset: 0, limit: expected),
          ).called(1);

          await gridCubit.selectChip(SearchCategory.playlists);
          verify(
            () => mockSearch.playlists('rock', offset: 0, limit: expected),
          ).called(1);

          await gridCubit.close();
        }
      });

      test('tracks keeps the raw pageSize regardless of columns', () async {
        cubit.updateGridColumns(3);

        when(
          () => mockSearch.tracks('rock', offset: 0, limit: 20),
        ).thenAnswer(
          (_) async => const PaginatedResult<Track>(
            items: [],
            total: 0,
            offset: 0,
            limit: 0,
          ),
        );

        cubit.onQueryChanged('rock');
        await cubit.selectChip(SearchCategory.tracks);

        verify(
          () => mockSearch.tracks('rock', offset: 0, limit: 20),
        ).called(1);
      });

      test('loadMore for a grid category uses the column-aligned limit',
          () async {
        const columns = 3;
        const expected = 21; // pageSizeForColumns(20, 3)

        final gridCubit = SearchCubit(mockEngine, pageSize: 20);
        gridCubit.updateGridColumns(columns);

        when(
          () => mockSearch.albums('rock', offset: 0, limit: expected),
        ).thenAnswer(
          (_) async => PaginatedResult<Album>(
            items: buildAlbums(expected),
            total: expected * 2,
            offset: 0,
            limit: expected,
          ),
        );
        when(
          () => mockSearch.albums(
            'rock',
            offset: expected,
            limit: expected,
          ),
        ).thenAnswer(
          (_) async => PaginatedResult<Album>(
            items: buildAlbums(expected),
            total: expected * 2,
            offset: expected,
            limit: expected,
          ),
        );

        gridCubit.onQueryChanged('rock');
        await gridCubit.selectChip(SearchCategory.albums);
        expect(gridCubit.state.hasMore, isTrue);

        await gridCubit.loadMore();

        verify(
          () => mockSearch.albums(
            'rock',
            offset: expected,
            limit: expected,
          ),
        ).called(1);
        expect(gridCubit.state.albumResults?.items.length, expected * 2);

        await gridCubit.close();
      });
    });
  });
}
