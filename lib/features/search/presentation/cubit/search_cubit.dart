import 'dart:async';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/search_repository.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';

class SearchCubit extends SafeCubit<SearchState> {
  final SearchRepository _search;
  final NoticeBus _notices;
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
    this._search,
    this._notices, {
    this.debounceDuration = const Duration(milliseconds: 350),
    this.pageSize = 20,
  }) : super(const SearchState());

  static const _emptyAll = SearchResponse(
    tracks: [],
    albums: [],
    artists: [],
    playlists: [],
  );

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

  Future<void> loadChips() async {
    if (!_search.hasMetadata) return;
    try {
      final chips = await _search.chips();
      if (!isClosed) emit(state.copyWith(chips: chips));
    } catch (_) {
      // chips() is optional: fall back to every known category.
      if (!isClosed) emit(state.copyWith(chips: SearchCategory.values));
    }
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query == state.query) return;

    if (query.trim().isEmpty) {
      // Rebuilding the state resets every section (results and errors).
      emit(SearchState(query: query, chips: state.chips, filter: state.filter));
      return;
    }

    emit(state.copyWith(query: query));
    _debounceTimer = Timer(debounceDuration, () {
      search(query);
    });
  }

  Future<void> selectChip(SearchCategory? category) async {
    final filter = SearchFilter.fromCategory(category);
    if (state.filter == filter) return;

    emit(state.copyWith(filter: filter));

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

    if (!_search.hasMetadata) {
      emit(_activeError(state, PluginNotLoadedException(), keepData: false));
      return;
    }

    emit(_activeLoading(state, keepData: false).copyWith(query: query));

    try {
      final filter = state.filter;

      switch (filter) {
        case SearchFilter.tracks:
          final res = await _search.tracks(
            cleanQuery,
            offset: 0,
            limit: pageSize,
          );
          emit(state.copyWith(tracks: SectionState.success(res)));
          break;
        case SearchFilter.albums:
          final res = await _search.albums(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          emit(state.copyWith(albums: SectionState.success(res)));
          break;
        case SearchFilter.artists:
          final res = await _search.artists(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          emit(state.copyWith(artists: SectionState.success(res)));
          break;
        case SearchFilter.playlists:
          final res = await _search.playlists(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          emit(state.copyWith(playlists: SectionState.success(res)));
          break;
        case SearchFilter.all:
          final results = await _search.all(cleanQuery);
          emit(state.copyWith(all: SectionState.success(results)));
      }
    } catch (e) {
      emit(_activeError(state, e, keepData: false));
      if (e.needsNotice) _notices.emit(Notice.error(e));
    }
  }

  Future<void> loadMore() async {
    final filter = state.filter;
    if (filter == SearchFilter.all ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    if (!_search.hasMetadata) return;

    emit(_activeLoading(state, keepData: true));

    try {
      final cleanQuery = state.query.trim();

      switch (filter) {
        case SearchFilter.tracks:
          final current = state.tracks.data;
          final res = await _search.tracks(
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
          emit(state.copyWith(tracks: SectionState.success(updated)));
          break;
        case SearchFilter.albums:
          final current = state.albums.data;
          final res = await _search.albums(
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
          emit(state.copyWith(albums: SectionState.success(updated)));
          break;
        case SearchFilter.artists:
          final current = state.artists.data;
          final res = await _search.artists(
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
          emit(state.copyWith(artists: SectionState.success(updated)));
          break;
        case SearchFilter.playlists:
          final current = state.playlists.data;
          final res = await _search.playlists(
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
          emit(state.copyWith(playlists: SectionState.success(updated)));
          break;
        case SearchFilter.all:
          break;
      }
    } catch (e) {
      emit(_activeError(state, e, keepData: true));
      if (e.needsNotice) _notices.emit(Notice.error(e));
    }
  }

  SearchState _activeLoading(SearchState state, {required bool keepData}) {
    return switch (state.filter) {
      SearchFilter.all => state.copyWith(
        all: SectionState.loading(keepData ? state.all.data : _emptyAll),
      ),
      SearchFilter.tracks => state.copyWith(
        tracks: SectionState.loading(
          keepData ? state.tracks.data : const PaginatedResult<Track>.empty(),
        ),
      ),
      SearchFilter.albums => state.copyWith(
        albums: SectionState.loading(
          keepData ? state.albums.data : const PaginatedResult<Album>.empty(),
        ),
      ),
      SearchFilter.artists => state.copyWith(
        artists: SectionState.loading(
          keepData ? state.artists.data : const PaginatedResult<Artist>.empty(),
        ),
      ),
      SearchFilter.playlists => state.copyWith(
        playlists: SectionState.loading(
          keepData
              ? state.playlists.data
              : const PaginatedResult<Playlist>.empty(),
        ),
      ),
    };
  }

  SearchState _activeError(
    SearchState state,
    Object error, {
    required bool keepData,
  }) {
    return switch (state.filter) {
      SearchFilter.all => state.copyWith(
        all: SectionState.error(error, keepData ? state.all.data : _emptyAll),
      ),
      SearchFilter.tracks => state.copyWith(
        tracks: SectionState.error(
          error,
          keepData ? state.tracks.data : const PaginatedResult<Track>.empty(),
        ),
      ),
      SearchFilter.albums => state.copyWith(
        albums: SectionState.error(
          error,
          keepData ? state.albums.data : const PaginatedResult<Album>.empty(),
        ),
      ),
      SearchFilter.artists => state.copyWith(
        artists: SectionState.error(
          error,
          keepData ? state.artists.data : const PaginatedResult<Artist>.empty(),
        ),
      ),
      SearchFilter.playlists => state.copyWith(
        playlists: SectionState.error(
          error,
          keepData
              ? state.playlists.data
              : const PaginatedResult<Playlist>.empty(),
        ),
      ),
    };
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
