import 'dart:async';

import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/features/library/presentation/cubit/library_state.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

class LibraryCubit extends SafeCubit<LibraryState> {
  final LibraryRepository _library;
  final NoticeBus _notices;
  final PlaylistRepository _playlist;
  final UserSession _session;
  final UserSavedMediaIndex _savedMedia;
  final int pageSize;
  StreamSubscription<bool>? _authSubscription;
  StreamSubscription<MediaItemType>? _savedMediaSubscription;

  /// Sections with a reload in flight, to never fetch one twice.
  final Set<LibrarySection> _reloading = {};

  int _gridColumns = 2;

  LibraryCubit(
    this._library,
    this._notices, {
    required this._playlist,
    this.pageSize = 20,
    required this._session,
    required this._savedMedia,
  }) : super(const LibraryState()) {
    _savedMediaSubscription = _savedMedia.savedChanges.listen(
      _onSavedMediaChanged,
    );
    _authSubscription = _session.authenticationChanges.listen((_) {
      if (!isClosed) loadAll();
    });
  }

  void _onSavedMediaChanged(MediaItemType type) {
    if (isClosed || !_session.isAuthenticated) return;
    switch (type) {
      case MediaItemType.album:
        unawaited(_loadAlbums());
      case MediaItemType.artist:
        unawaited(_loadArtists());
      case MediaItemType.playlist:
        unawaited(_loadPlaylists());
      case MediaItemType.track:
        break;
    }
  }

  int get _gridPageSize =>
      MediaCardMetrics.pageSizeForColumns(pageSize, _gridColumns);

  /// Reloads one section (pull-to-refresh), refreshing the saved set silently:
  /// an announced change would reload the section again.
  Future<void> refresh(LibrarySection section) async {
    if (!_library.hasMetadata || !_session.isAuthenticated) return;
    await Future.wait([
      switch (section) {
        LibrarySection.playlists => _loadPlaylists(),
        LibrarySection.albums => _loadAlbums(),
        LibrarySection.artists => _loadArtists(),
      },
      _savedMedia.refresh(_mediaTypeOf(section), notify: false),
    ]);
  }

  MediaItemType _mediaTypeOf(LibrarySection section) => switch (section) {
    LibrarySection.playlists => MediaItemType.playlist,
    LibrarySection.albums => MediaItemType.album,
    LibrarySection.artists => MediaItemType.artist,
  };

  void updateGridColumns(int columns) {
    if (columns <= 0 || columns == _gridColumns) return;
    _gridColumns = columns;
  }

  Future<void> loadAll() async {
    if (!_library.hasMetadata) {
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

    if (!_session.isAuthenticated) {
      emit(const LibraryState());
      return;
    }

    unawaited(_loadPlaylists());
    unawaited(_loadAlbums());
    unawaited(_loadArtists());
  }

  Future<void> loadMore(LibrarySection section) {
    return switch (section) {
      LibrarySection.playlists => _loadMore<Playlist>(
        current: state.playlists,
        fetch: (offset, limit) =>
            _library.savedPlaylists(offset: offset, limit: limit),
        update: (section) => state.copyWith(playlists: section),
      ),
      LibrarySection.albums => _loadMore<Album>(
        current: state.albums,
        fetch: (offset, limit) =>
            _library.savedAlbums(offset: offset, limit: limit),
        update: (section) => state.copyWith(albums: section),
      ),
      LibrarySection.artists => _loadMore<Artist>(
        current: state.artists,
        fetch: (offset, limit) =>
            _library.savedArtists(offset: offset, limit: limit),
        update: (section) => state.copyWith(artists: section),
      ),
    };
  }

  /// Null on failure (announced on the notice bus).
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    if (!_library.hasMetadata) return null;
    try {
      final playlist = await _playlist.createPlaylist(
        name,
        description: description,
        isPublic: isPublic,
      );
      // Announce it so the Playlists tab reloads instead of staying stale.
      if (playlist != null) {
        await _savedMedia.refresh(MediaItemType.playlist);
      }
      return playlist;
    } catch (e) {
      _notices.emit(Notice.error(e));
      return null;
    }
  }

  Future<void> _loadPlaylists() async {
    if (!_reloading.add(LibrarySection.playlists)) return;
    emit(state.copyWith(playlists: SectionState.loading(state.playlists.data)));
    try {
      final result = await _library.savedPlaylists(
        offset: 0,
        limit: _gridPageSize,
      );
      emit(state.copyWith(playlists: SectionState.success(result)));
    } catch (e) {
      emit(
        state.copyWith(playlists: SectionState.error(e, state.playlists.data)),
      );
      if (e.needsNotice) _notices.emit(Notice.error(e));
    } finally {
      _reloading.remove(LibrarySection.playlists);
    }
  }

  Future<void> _loadAlbums() async {
    if (!_reloading.add(LibrarySection.albums)) return;
    emit(state.copyWith(albums: SectionState.loading(state.albums.data)));
    try {
      final result = await _library.savedAlbums(
        offset: 0,
        limit: _gridPageSize,
      );
      emit(state.copyWith(albums: SectionState.success(result)));
    } catch (e) {
      emit(state.copyWith(albums: SectionState.error(e, state.albums.data)));
      if (e.needsNotice) _notices.emit(Notice.error(e));
    } finally {
      _reloading.remove(LibrarySection.albums);
    }
  }

  Future<void> _loadArtists() async {
    if (!_reloading.add(LibrarySection.artists)) return;
    emit(state.copyWith(artists: SectionState.loading(state.artists.data)));
    try {
      final result = await _library.savedArtists(
        offset: 0,
        limit: _gridPageSize,
      );
      emit(state.copyWith(artists: SectionState.success(result)));
    } catch (e) {
      emit(state.copyWith(artists: SectionState.error(e, state.artists.data)));
      if (e.needsNotice) _notices.emit(Notice.error(e));
    } finally {
      _reloading.remove(LibrarySection.artists);
    }
  }

  Future<void> _loadMore<T extends Object>({
    required SectionState<PaginatedResult<T>> current,
    required Future<PaginatedResult<T>> Function(int offset, int limit) fetch,
    required LibraryState Function(SectionState<PaginatedResult<T>>) update,
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
      if (e.needsNotice) _notices.emit(Notice.error(e));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _savedMediaSubscription?.cancel();
    return super.close();
  }
}
