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
  int _requestSeq = 0;
  final Duration debounceDuration;
  final int pageSize;

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

  int get _gridPageSize =>
      MediaCardMetrics.pageSizeForColumns(pageSize, _gridColumns);

  bool _isCurrent(int seq) => seq == _requestSeq && !isClosed;

  bool _emitIfCurrent(int seq, SearchState next) {
    if (!_isCurrent(seq)) return false;
    emit(next);
    return true;
  }

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
      if (!isClosed) emit(state.copyWith(chips: SearchCategory.values));
    }
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query == state.query) return;
    ++_requestSeq;

    if (query.trim().isEmpty) {
      // A fresh state (not copyWith) also clears past results and errors.
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
    final seq = ++_requestSeq;
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
          _emitIfCurrent(
            seq,
            state.copyWith(tracks: SectionState.success(res)),
          );
          break;
        case SearchFilter.albums:
          final res = await _search.albums(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          _emitIfCurrent(
            seq,
            state.copyWith(albums: SectionState.success(res)),
          );
          break;
        case SearchFilter.artists:
          final res = await _search.artists(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          _emitIfCurrent(
            seq,
            state.copyWith(artists: SectionState.success(res)),
          );
          break;
        case SearchFilter.playlists:
          final res = await _search.playlists(
            cleanQuery,
            offset: 0,
            limit: _gridPageSize,
          );
          _emitIfCurrent(
            seq,
            state.copyWith(playlists: SectionState.success(res)),
          );
          break;
        case SearchFilter.all:
          final results = await _search.all(cleanQuery);
          _emitIfCurrent(
            seq,
            state.copyWith(all: SectionState.success(results)),
          );
      }
    } catch (e) {
      final emitted = _emitIfCurrent(
        seq,
        _activeError(state, e, keepData: false),
      );
      if (emitted && e.needsNotice) _notices.emit(Notice.error(e));
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

    final seq = ++_requestSeq;
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
          _emitIfCurrent(
            seq,
            state.copyWith(tracks: SectionState.success(updated)),
          );
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
          _emitIfCurrent(
            seq,
            state.copyWith(albums: SectionState.success(updated)),
          );
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
          _emitIfCurrent(
            seq,
            state.copyWith(artists: SectionState.success(updated)),
          );
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
          _emitIfCurrent(
            seq,
            state.copyWith(playlists: SectionState.success(updated)),
          );
          break;
        case SearchFilter.all:
          break;
      }
    } catch (e) {
      final emitted = _emitIfCurrent(
        seq,
        _activeError(state, e, keepData: true),
      );
      if (emitted && e.needsNotice) _notices.emit(Notice.error(e));
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
