import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/search.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';

void main() {
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
      expect(state.resolvedCategory, equals(SearchCategory.all));
      expect(state.hasMore, isFalse);
    });

    test('resolvedCategory maps chips correctly', () {
      expect(
        const SearchState(selectedChip: 'Songs').resolvedCategory,
        equals(SearchCategory.tracks),
      );
      expect(
        const SearchState(selectedChip: 'tracks').resolvedCategory,
        equals(SearchCategory.tracks),
      );
      expect(
        const SearchState(selectedChip: 'Albums').resolvedCategory,
        equals(SearchCategory.albums),
      );
      expect(
        const SearchState(selectedChip: 'Artists').resolvedCategory,
        equals(SearchCategory.artists),
      );
      expect(
        const SearchState(selectedChip: 'Playlists').resolvedCategory,
        equals(SearchCategory.playlists),
      );
      expect(
        const SearchState(selectedChip: 'All').resolvedCategory,
        equals(SearchCategory.all),
      );
      expect(
        const SearchState(selectedChip: 'UnknownCategory').resolvedCategory,
        equals(SearchCategory.all),
      );
    });

    test('hasResults and hasMore check all and category-specific results', () {
      final searchResponse = SearchResponse(
        tracks: [
          Track(
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
          ),
        ],
        albums: [],
        artists: [],
        playlists: [],
      );

      final stateWithAll = SearchState(
        query: 'test',
        allResults: searchResponse,
      );
      expect(stateWithAll.hasResults, isTrue);
      expect(stateWithAll.hasMore, isFalse);

      final trackPagination = PaginatedResult<Track>(
        items: searchResponse.tracks,
        total: 10,
        offset: 0,
        limit: 1,
      );

      final stateWithCategory = SearchState(
        query: 'test',
        selectedChip: 'Tracks',
        trackResults: trackPagination,
      );
      expect(stateWithCategory.isAllCategory, isFalse);
      expect(stateWithCategory.hasResults, isTrue);
      expect(stateWithCategory.hasMore, isTrue);
    });

    test('copyWith updates state or clears specific fields', () {
      const state = SearchState(query: 'initial', isLoading: true);
      final updated = state.copyWith(
        query: 'updated',
        isLoading: false,
        selectedChip: 'Songs',
      );

      expect(updated.query, equals('updated'));
      expect(updated.isLoading, isFalse);
      expect(updated.selectedChip, equals('Songs'));

      final cleared = updated.copyWith(clearSelectedChip: true);
      expect(cleared.selectedChip, isNull);
    });
  });
}
