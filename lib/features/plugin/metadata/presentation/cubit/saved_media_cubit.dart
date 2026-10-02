import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_state.dart';

/// Global index of the signed-in user's saved media, plus the save actions.
///
/// Deliberately small (IDs only) and global: the paginated listings belong to
/// the page cubits, but *any* page needs to know "is this saved?" and to
/// toggle it, because the actions live in the search, the detail pages, the
/// player and the track sheet. Loading is lazy per media type.
///
/// [auth] is the single account source (current state + changes): the index
/// belongs to the current account, so it must be dropped when the account
/// changes.
class SavedMediaCubit extends SafeCubit<SavedMediaState> {
  final LibraryRepository _library;
  final NoticeBus _notices;
  final Set<MediaItemType> _loading = {};
  final StateStreamable<AccountState> _auth;
  StreamSubscription<AccountState>? _authSubscription;

  SavedMediaCubit(
    this._library,
    this._notices, {
    required StateStreamable<AccountState> auth,
  }) : _auth = auth,
       super(const SavedMediaState()) {
    _authSubscription = auth.stream.listen(_onAccountChanged);
    _onAccountChanged(auth.state);
  }

  void _onAccountChanged(AccountState state) {
    if (isClosed) return;
    if (state.isAuthenticated) {
      // Warm the index in the background: the saved set belongs to the
      // account, so it loads with it instead of being requested by each page.
      unawaited(_ensureLoaded(MediaItemType.track));
      unawaited(_ensureLoaded(MediaItemType.album));
      unawaited(_ensureLoaded(MediaItemType.artist));
      unawaited(_ensureLoaded(MediaItemType.playlist));
    } else {
      reset();
    }
  }

  /// Drops the cached IDs, e.g. on sign-in/sign-out so the next access reloads.
  void reset() => emit(const SavedMediaState());

  bool isTrackSaved(String id) => state.isTrackSaved(id);
  bool isAlbumSaved(String id) => state.isAlbumSaved(id);
  bool isArtistSaved(String id) => state.isArtistSaved(id);
  bool isPlaylistSaved(String id) => state.isPlaylistSaved(id);

  Future<void> _ensureLoaded(MediaItemType type) async {
    if (state.loaded.contains(type) || _loading.contains(type)) return;
    if (!_library.hasMetadata) return;
    if (!_auth.state.isAuthenticated) {
      emit(state.copyWith(loaded: {...state.loaded, type}));
      return;
    }

    _loading.add(type);
    try {
      final ids = await _loadIds(type);
      emit(state.withIds(type, ids).copyWith(loaded: {...state.loaded, type}));
    } catch (_) {
      // Background load: stays silent and retries on the next access.
    } finally {
      _loading.remove(type);
    }
  }

  Future<void> toggleTrack(Track track) => _toggle(
    type: MediaItemType.track,
    id: track.id,
    save: () => _library.saveTrack(track.id),
    unsave: () => _library.unsaveTrack(track.id),
  );

  Future<void> toggleAlbum(Album album) => _toggle(
    type: MediaItemType.album,
    id: album.id,
    save: () => _library.saveAlbum(album.id),
    unsave: () => _library.unsaveAlbum(album.id),
  );

  Future<void> toggleArtist(Artist artist) => _toggle(
    type: MediaItemType.artist,
    id: artist.id,
    save: () => _library.saveArtist(artist.id),
    unsave: () => _library.unsaveArtist(artist.id),
  );

  Future<void> togglePlaylist(Playlist playlist) => _toggle(
    type: MediaItemType.playlist,
    id: playlist.id,
    save: () => _library.savePlaylist(playlist.id),
    unsave: () => _library.unsavePlaylist(playlist.id),
  );

  /// Flips the ID optimistically, reverts and notifies if the write fails.
  Future<void> _toggle({
    required MediaItemType type,
    required String id,
    required Future<void> Function() save,
    required Future<void> Function() unsave,
  }) async {
    final wasSaved = state.isSaved(type, id);
    final previous = state.idsOf(type).toSet();

    emit(state.withIds(type, _flip(previous, id, !wasSaved)));
    try {
      await (wasSaved ? unsave() : save());
    } catch (e) {
      emit(state.withIds(type, previous));
      _notices.emit(e);
    }
  }

  Set<String> _flip(Set<String> ids, String id, bool saved) {
    final next = {...ids};
    if (saved) {
      next.add(id);
    } else {
      next.remove(id);
    }
    return next;
  }

  Future<Set<String>> _loadIds(MediaItemType type) {
    return switch (type) {
      MediaItemType.track => _pageAll<Track>(
        (o, l) => _library.savedTracks(offset: o, limit: l),
        (t) => t.id,
      ),
      MediaItemType.album => _pageAll<Album>(
        (o, l) => _library.savedAlbums(offset: o, limit: l),
        (a) => a.id,
      ),
      MediaItemType.artist => _pageAll<Artist>(
        (o, l) => _library.savedArtists(offset: o, limit: l),
        (a) => a.id,
      ),
      MediaItemType.playlist => _pageAll<Playlist>(
        (o, l) => _library.savedPlaylists(offset: o, limit: l),
        (p) => p.id,
      ),
    };
  }

  Future<Set<String>> _pageAll<T extends Object>(
    Future<PaginatedResult<T>> Function(int offset, int limit) page,
    String Function(T item) idOf,
  ) async {
    const size = 100;
    final ids = <String>{};
    var offset = 0;
    while (true) {
      final result = await page(offset, size);
      ids.addAll(result.items.map(idOf));
      offset += result.items.length;
      // Guard against a provider that reports more items than it returns.
      if (result.items.isEmpty || offset >= result.total) break;
    }
    return ids;
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
