import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
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
      expect(state.selectedChip, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
      expect(state.loadMoreError, isNull);
      expect(state.allResults, isNull);
      expect(state.isAllCategory, isTrue);
      expect(state.isEmptyQuery, isTrue);
      expect(state.hasResults, isFalse);
      expect(state.hasMore, isFalse);
    });

    test('a null selection is the aggregate view and is never paged', () {
      final state = SearchState(
        allResults: SearchResponse(
          tracks: [dummyTrack],
          albums: [],
          artists: [],
          playlists: [],
        ),
      );

      expect(state.isAllCategory, isTrue);
      expect(state.hasResults, isTrue);
      expect(state.hasMore, isFalse);
    });

    test('hasResults/hasMore read only the selected category results', () {
      final paginated = SearchState(
        selectedChip: SearchCategory.albums,
        albumResults: PaginatedResult<Album>(
          items: [dummyAlbum],
          total: 2,
          offset: 0,
          limit: 1,
        ),
      );

      expect(paginated.isAllCategory, isFalse);
      expect(paginated.hasResults, isTrue);
      expect(paginated.hasMore, isTrue);

      expect(
        paginated.copyWith(selectedChip: SearchCategory.artists).hasResults,
        isFalse,
      );
      expect(
        paginated.copyWith(selectedChip: SearchCategory.artists).hasMore,
        isFalse,
      );
    });

    test('a fully loaded category has no more pages', () {
      final state = SearchState(
        selectedChip: SearchCategory.albums,
        albumResults: PaginatedResult<Album>(
          items: [dummyAlbum, dummyAlbum],
          total: 2,
          offset: 0,
          limit: 2,
        ),
      );

      expect(state.hasResults, isTrue);
      expect(state.hasMore, isFalse);
    });

    test('a category without loaded results has nothing to show', () {
      expect(
        const SearchState(selectedChip: SearchCategory.tracks).hasResults,
        isFalse,
      );
      expect(
        const SearchState(selectedChip: SearchCategory.playlists).hasMore,
        isFalse,
      );
    });

    test('copyWith updates state or clears specific fields', () {
      const state = SearchState(query: 'initial', isLoading: true);
      final updated = state.copyWith(
        query: 'updated',
        isLoading: false,
        selectedChip: SearchCategory.tracks,
        chips: const [SearchCategory.tracks, SearchCategory.albums],
      );

      expect(updated.query, equals('updated'));
      expect(updated.isLoading, isFalse);
      expect(updated.selectedChip, equals(SearchCategory.tracks));
      expect(
        updated.chips,
        equals(const [SearchCategory.tracks, SearchCategory.albums]),
      );

      final cleared = updated.copyWith(clearSelectedChip: true);
      expect(cleared.selectedChip, isNull);
      expect(cleared.isAllCategory, isTrue);
    });
  });
}
