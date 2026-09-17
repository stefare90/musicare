import 'dart:async';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/search.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';

class SearchCubit extends SafeCubit<SearchState> {
  final MetadataPluginEngine _pluginEngine;
  Timer? _debounceTimer;
  final Duration debounceDuration;
  final int pageSize;

  /// Number of grid columns currently used by the search results grid.
  ///
  /// Defaults to 2 (the narrow-phone layout) and is only updated by the view
  /// through [updateGridColumns]; it drives the pagination `limit` so grids
  /// never end with a partially filled row.
  int _gridColumns = 2;

  SearchCubit(
    this._pluginEngine, {
    this.debounceDuration = const Duration(milliseconds: 350),
    this.pageSize = 20,
  }) : super(const SearchState());

  /// Pagination size rounded up to a whole number of grid rows.
  int get _gridPageSize =>
      MediaCardMetrics.pageSizeForColumns(pageSize, _gridColumns);

  /// Records the number of columns of the results grid.
  ///
  /// This is deliberately a pure setter: it never emits a new state, so the
  /// view can call it from a post-frame callback without triggering a rebuild
  /// loop. Requests made before the first notification use the default of 2.
  void updateGridColumns(int columns) {
    if (columns <= 0 || columns == _gridColumns) return;
    _gridColumns = columns;
  }

  void loadChips() {
    if (!_pluginEngine.hasMetadata) return;
    try {
      emit(state.copyWith(chips: _pluginEngine.metadata.search.chips()));
    } catch (_) {
      // chips() is optional: fall back to every known category.
      emit(state.copyWith(chips: SearchCategory.values));
    }
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query == state.query) return;

    if (query.trim().isEmpty) {
      emit(
        state.copyWith(
          query: query,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
          clearLoadMoreError: true,
          clearAllResults: true,
          clearTrackResults: true,
          clearAlbumResults: true,
          clearArtistResults: true,
          clearPlaylistResults: true,
        ),
      );
      return;
    }

    emit(state.copyWith(query: query));
    _debounceTimer = Timer(debounceDuration, () {
      search(query);
    });
  }

  Future<void> selectChip(SearchCategory? category) async {
    if (state.selectedChip == category) return;

    emit(
      state.copyWith(
        selectedChip: category,
        clearSelectedChip: category == null,
        clearTrackResults: true,
        clearAlbumResults: true,
        clearArtistResults: true,
        clearPlaylistResults: true,
        clearError: true,
        clearLoadMoreError: true,
      ),
    );

    if (state.query.trim().isNotEmpty) {
      await search(state.query);
    }
  }

  Future<void> retry() async {
    if (state.query.trim().isEmpty) return;
    await search(state.query);
  }

  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    if (!_pluginEngine.hasMetadata) {
      emit(state.copyWith(isLoading: false, error: PluginNotLoadedException()));
      return;
    }

    emit(
      state.copyWith(
        query: query,
        isLoading: true,
        clearError: true,
        clearLoadMoreError: true,
      ),
    );

    try {
      final searchApi = _pluginEngine.metadata.search;
      final category = state.selectedChip;

      switch (category) {
        case SearchCategory.tracks:
          final res = await searchApi.tracks(
            cleanQuery,
            offset: 0,
            limit: pageSize,
          );
          emit(
            state.copyWith(
              isLoading: false,
              trackResults: res,
              clearError: true,
            ),
          );
          break;
        case SearchCategory.albums:
          final res = await searchApi.albums(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          emit(
            state.copyWith(
              isLoading: false,
              albumResults: res,
              clearError: true,
            ),
          );
          break;
        case SearchCategory.artists:
          final res = await searchApi.artists(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          emit(
            state.copyWith(
              isLoading: false,
              artistResults: res,
              clearError: true,
            ),
          );
          break;
        case SearchCategory.playlists:
          final res = await searchApi.playlists(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          emit(
            state.copyWith(
              isLoading: false,
              playlistResults: res,
              clearError: true,
            ),
          );
          break;
        case null:
          final results = await searchApi.all(cleanQuery);
          emit(
            state.copyWith(
              isLoading: false,
              allResults: results,
              clearError: true,
            ),
          );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e));
    }
  }

  Future<void> loadMore() async {
    final category = state.selectedChip;
    if (category == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    if (!_pluginEngine.hasMetadata) return;

    emit(state.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    try {
      final searchApi = _pluginEngine.metadata.search;
      final cleanQuery = state.query.trim();

      switch (category) {
        case SearchCategory.tracks:
          final current = state.trackResults!;
          final res = await searchApi.tracks(
            cleanQuery,
            offset: current.items.length,
            limit: pageSize,
          );
          final updated = PaginatedResult<Track>(
            items: [...current.items, ...res.items],
            total: res.total,
            offset: res.offset,
            limit: res.limit,
          );
          emit(state.copyWith(isLoadingMore: false, trackResults: updated));
          break;
        case SearchCategory.albums:
          final current = state.albumResults!;
          final res = await searchApi.albums(
            cleanQuery,
            offset: current.items.length,
            limit: _gridPageSize,
          );
          final updated = PaginatedResult<Album>(
            items: [...current.items, ...res.items],
            total: res.total,
            offset: res.offset,
            limit: res.limit,
          );
          emit(state.copyWith(isLoadingMore: false, albumResults: updated));
          break;
        case SearchCategory.artists:
          final current = state.artistResults!;
          final res = await searchApi.artists(
            cleanQuery,
            offset: current.items.length,
            limit: _gridPageSize,
          );
          final updated = PaginatedResult<Artist>(
            items: [...current.items, ...res.items],
            total: res.total,
            offset: res.offset,
            limit: res.limit,
          );
          emit(state.copyWith(isLoadingMore: false, artistResults: updated));
          break;
        case SearchCategory.playlists:
          final current = state.playlistResults!;
          final res = await searchApi.playlists(
            cleanQuery,
            offset: current.items.length,
            limit: _gridPageSize,
          );
          final updated = PaginatedResult<Playlist>(
            items: [...current.items, ...res.items],
            total: res.total,
            offset: res.offset,
            limit: res.limit,
          );
          emit(state.copyWith(isLoadingMore: false, playlistResults: updated));
          break;
      }
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, loadMoreError: e));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
