import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';

void main() {
  final dummyTrack = Track(
    id: 't1',
    name: 'Song 1',
    externalUri: '',
    artists: [],
    album: Album(
      id: 'a1',
      name: 'Alb',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    ),
    durationMs: 1000,
  );

  final dummyAlbum = Album(
    id: 'al1',
    name: 'Album 1',
    artists: const [],
    releaseDate: '2023',
    externalUri: '',
    totalTracks: 10,
    albumType: AlbumType.album,
  );

  group('SearchState Unit Tests', () {
    test('initial state has default values', () {
      const state = SearchState();
      expect(state.query, isEmpty);
      expect(state.chips, isEmpty);
      expect(state.filter, SearchFilter.all);
      expect(state.selectedChip, isNull);
      expect(state.isAllCategory, isTrue);
      expect(state.isEmptyQuery, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
      expect(state.loadMoreError, isNull);
      expect(state.hasResults, isFalse);
      expect(state.hasMore, isFalse);
    });

    test('a null selection is the aggregate view and is never paged', () {
      final state = SearchState(
        all: SectionState.success(
          SearchResponse(
            tracks: [dummyTrack],
            albums: [],
            artists: [],
            playlists: [],
          ),
        ),
      );

      expect(state.isAllCategory, isTrue);
      expect(state.hasResults, isTrue);
      expect(state.hasMore, isFalse);
    });

    test('hasResults/hasMore read only the selected category results', () {
      final paginated = SearchState(
        filter: SearchFilter.albums,
        albums: SectionState.success(
          PaginatedResult<Album>(
            items: [dummyAlbum],
            total: 2,
            offset: 0,
            limit: 1,
          ),
        ),
      );

      expect(paginated.isAllCategory, isFalse);
      expect(paginated.hasResults, isTrue);
      expect(paginated.hasMore, isTrue);

      expect(
        paginated.copyWith(filter: SearchFilter.artists).hasResults,
        isFalse,
      );
      expect(
        paginated.copyWith(filter: SearchFilter.artists).hasMore,
        isFalse,
      );
    });

    test('a fully loaded category has no more pages', () {
      final state = SearchState(
        filter: SearchFilter.albums,
        albums: SectionState.success(
          PaginatedResult<Album>(
            items: [dummyAlbum, dummyAlbum],
            total: 2,
            offset: 0,
            limit: 2,
          ),
        ),
      );

      expect(state.hasResults, isTrue);
      expect(state.hasMore, isFalse);
    });

    test('a category without loaded results has nothing to show', () {
      expect(
        const SearchState(filter: SearchFilter.tracks).hasResults,
        isFalse,
      );
      expect(
        const SearchState(filter: SearchFilter.playlists).hasMore,
        isFalse,
      );
    });

    test('copyWith updates query, chips and filter', () {
      const state = SearchState(query: 'initial');
      final updated = state.copyWith(
        query: 'updated',
        chips: const [SearchCategory.tracks, SearchCategory.albums],
        filter: SearchFilter.tracks,
      );

      expect(updated.query, equals('updated'));
      expect(
        updated.chips,
        equals(const [SearchCategory.tracks, SearchCategory.albums]),
      );
      expect(updated.filter, SearchFilter.tracks);
      expect(updated.selectedChip, SearchCategory.tracks);

      final cleared = updated.copyWith(filter: SearchFilter.all);
      expect(cleared.selectedChip, isNull);
      expect(cleared.isAllCategory, isTrue);
    });

    test('loading and errors are derived from the active section', () {
      final loading = const SearchState(filter: SearchFilter.albums).copyWith(
        albums: SectionState.loading(const PaginatedResult.empty()),
      );
      expect(loading.isLoading, isTrue);
      expect(loading.isLoadingMore, isFalse);
      expect(loading.error, isNull);
      expect(loading.hasResults, isFalse);

      final initialError = const SearchState(filter: SearchFilter.albums)
          .copyWith(
            albums: SectionState.error(
              Exception('boom'),
              const PaginatedResult.empty(),
            ),
          );
      expect(initialError.error, isNotNull);
      expect(initialError.loadMoreError, isNull);
      expect(initialError.isLoading, isFalse);

      final loaded = SearchState(
        filter: SearchFilter.albums,
        albums: SectionState.success(
          PaginatedResult<Album>(
            items: [dummyAlbum],
            total: 2,
            offset: 0,
            limit: 1,
          ),
        ),
      );

      final loadingMore = loaded.copyWith(
        albums: SectionState.loading(loaded.albums.data),
      );
      expect(loadingMore.isLoadingMore, isTrue);
      expect(loadingMore.isLoading, isFalse);
      expect(loadingMore.error, isNull);

      final loadMoreError = loaded.copyWith(
        albums: SectionState.error(Exception('boom'), loaded.albums.data),
      );
      expect(loadMoreError.loadMoreError, isNotNull);
      expect(loadMoreError.error, isNull);
      expect(loadMoreError.hasResults, isTrue);
    });

    test('SearchFilter maps to and from SearchCategory', () {
      expect(SearchFilter.fromCategory(null), SearchFilter.all);
      expect(
        SearchFilter.fromCategory(SearchCategory.tracks),
        SearchFilter.tracks,
      );
      expect(SearchFilter.all.category, isNull);
      expect(SearchFilter.playlists.category, SearchCategory.playlists);
    });
  });
}
