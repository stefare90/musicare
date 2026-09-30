import 'dart:async';

import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/features/library/presentation/cubit/library_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

/// The signed-in user's account collections (playlists, albums, artists).
///
/// The three sections load independently so the cheapest one (playlists) can
/// render while the others are still fetching, and each keeps its own
/// pagination and error. It only reads from the provider; the local downloads
/// live in the storage layer.
class LibraryCubit extends SafeCubit<LibraryState> {
  final MetadataPluginEngine _pluginEngine;
  final NoticeBus _notices;
  final int pageSize;

  /// Number of grid columns currently used by the library grids.
  ///
  /// Defaults to 2 (the narrow-phone layout) and is only updated by the view
  /// through [updateGridColumns]; it drives the pagination `limit` so grids
  /// never end with a partially filled row.
  int _gridColumns = 2;

  LibraryCubit(
    this._pluginEngine,
    this._notices, {
    this.pageSize = 20,
  }) : super(const LibraryState());

  /// Pagination size rounded up to a whole number of grid rows.
  int get _gridPageSize =>
      MediaCardMetrics.pageSizeForColumns(pageSize, _gridColumns);

  /// Records the number of columns of the grids.
  ///
  /// Deliberately a pure setter: it never emits, so the view can call it from a
  /// post-frame callback without triggering a rebuild loop. Loads that happen
  /// before the first notification use the default of 2.
  void updateGridColumns(int columns) {
    if (columns <= 0 || columns == _gridColumns) return;
    _gridColumns = columns;
  }

  Future<void> loadAll() async {
    if (!_pluginEngine.hasMetadata) {
      final error = PluginNotLoadedException();
      emit(
        LibraryState(
          playlists: SectionState.error(error, state.playlists.data),
          albums: SectionState.error(error, state.albums.data),
          artists: SectionState.error(error, state.artists.data),
        ),
      );
      return;
    }

    final isAuthenticated = await _pluginEngine.metadata.auth.isAuthenticated();
    if (!isAuthenticated) {
      emit(const LibraryState());
      return;
    }

    emit(state.copyWith(isAuthenticated: true));
    unawaited(_loadPlaylists());
    unawaited(_loadAlbums());
    unawaited(_loadArtists());
  }

  Future<void> loadMore(LibrarySection section) {
    return switch (section) {
      LibrarySection.playlists => _loadMore<Playlist>(
        current: state.playlists,
        fetch: (offset, limit) =>
            _pluginEngine.metadata.user.savedPlaylists(
              offset: offset,
              limit: limit,
            ),
        update: (section) => state.copyWith(playlists: section),
      ),
      LibrarySection.albums => _loadMore<Album>(
        current: state.albums,
        fetch: (offset, limit) =>
            _pluginEngine.metadata.user.savedAlbums(
              offset: offset,
              limit: limit,
            ),
        update: (section) => state.copyWith(albums: section),
      ),
      LibrarySection.artists => _loadMore<Artist>(
        current: state.artists,
        fetch: (offset, limit) =>
            _pluginEngine.metadata.user.savedArtists(
              offset: offset,
              limit: limit,
            ),
        update: (section) => state.copyWith(artists: section),
      ),
    };
  }

  Future<void> _loadPlaylists() async {
    emit(state.copyWith(playlists: SectionState.loading(state.playlists.data)));
    try {
      final result = await _pluginEngine.metadata.user.savedPlaylists(
        offset: 0,
        limit: _gridPageSize,
      );
      emit(state.copyWith(playlists: SectionState.success(result)));
    } catch (e) {
      emit(state.copyWith(playlists: SectionState.error(e, state.playlists.data)));
      if (e.needsNotice) _notices.emit(e);
    }
  }

  Future<void> _loadAlbums() async {
    emit(state.copyWith(albums: SectionState.loading(state.albums.data)));
    try {
      final result = await _pluginEngine.metadata.user.savedAlbums(
        offset: 0,
        limit: _gridPageSize,
      );
      emit(state.copyWith(albums: SectionState.success(result)));
    } catch (e) {
      emit(state.copyWith(albums: SectionState.error(e, state.albums.data)));
      if (e.needsNotice) _notices.emit(e);
    }
  }

  Future<void> _loadArtists() async {
    emit(state.copyWith(artists: SectionState.loading(state.artists.data)));
    try {
      final result = await _pluginEngine.metadata.user.savedArtists(
        offset: 0,
        limit: _gridPageSize,
      );
      emit(state.copyWith(artists: SectionState.success(result)));
    } catch (e) {
      emit(state.copyWith(artists: SectionState.error(e, state.artists.data)));
      if (e.needsNotice) _notices.emit(e);
    }
  }

  Future<void> _loadMore<T extends Object>({
    required SectionState<PaginatedResult<T>> current,
    required Future<PaginatedResult<T>> Function(int offset, int limit) fetch,
    required LibraryState Function(SectionState<PaginatedResult<T>>)
    update,
  }) async {
    if (current.isLoading) return;
    if (current.data.items.length >= current.data.total) return;

    emit(update(SectionState.loading(current.data)));
    final offset = current.data.items.length;
    try {
      final next = await fetch(offset, _gridPageSize);
      final combined = PaginatedResult<T>(
        items: [...current.data.items, ...next.items],
        total: next.total,
        offset: offset,
        limit: _gridPageSize,
      );
      emit(update(SectionState.success(combined)));
    } catch (e) {
      emit(update(SectionState.error(e, current.data)));
      if (e.needsNotice) _notices.emit(e);
    }
  }
}
