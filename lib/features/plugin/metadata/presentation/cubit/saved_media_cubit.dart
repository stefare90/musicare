import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_session.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_state.dart';

/// Global index of the signed-in user's saved media, plus the save actions.
///
/// Deliberately small (IDs only) and global: the paginated listings belong to
/// the page cubits, but *any* page needs to know "is this saved?" and to
/// toggle it, because the actions live in the search, the detail pages, the
/// player and the track sheet. The index warms up eagerly when the account
/// signs in, one set per media type. Through [changes] it also announces real
/// changes per type, so a listing (library tabs, liked songs) reloads without
/// polling the state.
///
/// [auth] is the single account source (current state + changes): the index
/// belongs to the current account, so it must be dropped when the account
/// changes.
class SavedMediaCubit extends SafeCubit<SavedMediaState> {
  final LibraryRepository _library;
  final NoticeBus _notices;
  final AccountSession _session;
  final Set<MediaItemType> _loading = {};
  final StreamController<MediaItemType> _changes =
      StreamController<MediaItemType>.broadcast();
  StreamSubscription<bool>? _authSubscription;

  /// Emits a type only for a genuine change (a successful toggle, or a refresh
  /// returning a different set), never for the warm-up or an identical refetch.
  Stream<MediaItemType> get changes => _changes.stream;

  /// Last settled set per type: lets [_applyLoaded] tell a real change from the
  /// warm-up (first read) and from a refresh that returned the same IDs.
  final Map<MediaItemType, Set<String>> _snapshot = {};

  /// Invalidates in-flight loads on [reset], so a load started under the old
  /// account can never repopulate the index of the new one.
  int _generation = 0;

  SavedMediaCubit(
    this._library,
    this._notices, {
    required AccountSession session,
  }) : _session = session,
       super(const SavedMediaState()) {
    _authSubscription = session.authenticationChanges.listen(_onAccountChanged);
    _onAccountChanged(session.isAuthenticated);
  }

  void _onAccountChanged(bool authenticated) {
    if (isClosed) return;
    if (authenticated) {
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
  ///
  /// Distinct from a [changes] event: the reset of the index is not a change a
  /// listing has to react to. The in-flight markers are dropped too, so a load
  /// started under the previous account does not block the new account's
  /// warm-up; its result is discarded by [_applyLoaded]'s generation check.
  void reset() {
    _generation++;
    _snapshot.clear();
    _loading.clear();
    emit(const SavedMediaState());
  }

  bool isTrackSaved(String id) => state.isTrackSaved(id);
  bool isAlbumSaved(String id) => state.isAlbumSaved(id);
  bool isArtistSaved(String id) => state.isArtistSaved(id);
  bool isPlaylistSaved(String id) => state.isPlaylistSaved(id);

  Future<void> _ensureLoaded(MediaItemType type) async {
    if (state.loaded.contains(type) || _loading.contains(type)) return;
    if (!_library.hasMetadata) return;
    if (!_session.isAuthenticated) {
      emit(state.copyWith(loaded: {...state.loaded, type}));
      return;
    }
    await _load(type);
  }

  /// Re-reads the saved IDs of [type] even when already loaded, announcing a
  /// change only if the returned set differs from the last one.
  ///
  /// Used after a write whose effect on the saved set is not inferable locally,
  /// such as creating a playlist.
  Future<void> refresh(MediaItemType type) async {
    if (_loading.contains(type)) return;
    if (!_library.hasMetadata || !_session.isAuthenticated) return;
    await _load(type);
  }

  Future<void> _load(MediaItemType type) async {
    final generation = _generation;
    _loading.add(type);
    try {
      _applyLoaded(type, await _loadIds(type), generation);
    } catch (_) {
      // Background load: stays silent and retries on the next access.
    } finally {
      _loading.remove(type);
    }
  }

  void _applyLoaded(MediaItemType type, Set<String> ids, int generation) {
    if (generation != _generation) return;
    final previous = _snapshot[type];
    _snapshot[type] = ids;

    emit(state.withIds(type, ids).copyWith(loaded: {...state.loaded, type}));
    // A missing previous set means this is the first read of the type: the
    // warm-up must not be announced as a change.
    if (previous != null && !setEquals(previous, ids)) {
      _changes.add(type);
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
    final optimistic = _flip(previous, id, !wasSaved);

    emit(state.withIds(type, optimistic));
    try {
      await (wasSaved ? unsave() : save());
      // Announce only after the write lands: a reload started optimistically
      // could read the server before the change is committed and stay stale.
      _snapshot[type] = optimistic;
      _changes.add(type);
      // Saving a playlist may persist a different id (a copy), so the requested
      // id is not authoritative: re-read the library and settle the set.
      if (type == MediaItemType.playlist) {
        await _load(type);
      }
    } catch (e) {
      _snapshot[type] = previous;
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
    await _changes.close();
    return super.close();
  }
}
