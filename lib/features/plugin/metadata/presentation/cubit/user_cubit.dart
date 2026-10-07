import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/account_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';

part 'user_favorites.dart';
part 'user_playlist_edits.dart';
part 'user_saved_media_index.dart';
part 'user_session.dart';
part 'user_state.dart';

/// [cancelled] stays silent, [failed] shows feedback.
enum AuthResult { authenticated, cancelled, failed }

class UserCubit extends SafeCubit<UserState>
    implements
        UserSession,
        UserFavorites,
        UserSavedMediaIndex,
        UserPlaylistEdits {
  UserCubit(this._account, this._library, this._notices, this._playlists)
    : super(const UserState());

  final AccountRepository _account;
  final LibraryRepository _library;
  final NoticeBus _notices;
  final PlaylistRepository _playlists;
  final Set<MediaItemType> _loading = {};
  final StreamController<MediaItemType> _savedChanges =
      StreamController<MediaItemType>.broadcast();
  final StreamController<PlaylistTracksChanged> _edits =
      StreamController<PlaylistTracksChanged>.broadcast();

  /// Last settled set per type, to announce only genuine changes.
  final Map<MediaItemType, Set<String>> _snapshot = {};

  /// Discards loads started under a previous account.
  int _generation = 0;

  @override
  bool get isAuthenticated => state.isAuthenticated;

  @override
  String? get userId => state.userId;

  @override
  Stream<bool> get authenticationChanges =>
      stream.map((state) => state.isAuthenticated).distinct();

  /// Emits only genuine changes, never the warm-up.
  @override
  Stream<MediaItemType> get savedChanges => _savedChanges.stream;

  @override
  Stream<PlaylistTracksChanged> get playlistEdits => _edits.stream;

  /// Emits the cached identity first: resolving it needs the network, which
  /// must never block `runApp` (offline boot).
  Future<void> initialize() async {
    if (!_account.hasMetadata) return;
    var isAuthenticated = false;
    try {
      isAuthenticated = await _account.isAuthenticated();
    } catch (_) {
    }
    if (isClosed) return;
    emit(
      UserState(
        isAuthenticated: isAuthenticated,
        userId: isAuthenticated ? _account.cachedUserId : null,
      ),
    );

    if (!isAuthenticated) return;
    _resetIndex();
    unawaited(_refreshIdentity());
    _warmUp();
  }

  Future<void> _refreshIdentity() async {
    try {
      final userId = await _account.resolveUserId();
      if (isClosed || userId == null || userId == state.userId) return;
      emit(state.copyWith(userId: userId));
    } catch (_) {
    }
  }

  Future<AuthResult> signIn() async {
    try {
      await _account.authenticate();
      final isAuthenticated = await _account.isAuthenticated();
      String? userId;
      if (isAuthenticated) {
        String? resolved;
        try {
          resolved = await _account.resolveUserId();
        } catch (_) {
          resolved = null;
        }
        userId = resolved ?? _account.cachedUserId;
      }
      if (isClosed) return AuthResult.cancelled;
      emit(UserState(isAuthenticated: isAuthenticated, userId: userId));
      if (isAuthenticated) {
        _resetIndex();
        _warmUp();
      }
      return isAuthenticated ? AuthResult.authenticated : AuthResult.cancelled;
    } catch (_) {
      return AuthResult.failed;
    }
  }

  Future<void> signOut() async {
    try {
      await _account.logout();
    } catch (_) {
    }
    _resetIndex();
    emit(const UserState());
  }

  /// Clears the saved index without signing out.
  void reset() {
    _resetIndex();
    emit(
      state.copyWith(
        trackIds: const {},
        albumIds: const {},
        artistIds: const {},
        playlistIds: const {},
        loaded: const {},
      ),
    );
  }

  void _resetIndex() {
    _generation++;
    _snapshot.clear();
    _loading.clear();
  }

  void _warmUp() {
    unawaited(_ensureLoaded(MediaItemType.track));
    unawaited(_ensureLoaded(MediaItemType.album));
    unawaited(_ensureLoaded(MediaItemType.artist));
    unawaited(_ensureLoaded(MediaItemType.playlist));
  }

  @override
  bool isTrackSaved(String id) => state.isTrackSaved(id);
  @override
  bool isAlbumSaved(String id) => state.isAlbumSaved(id);
  @override
  bool isArtistSaved(String id) => state.isArtistSaved(id);
  @override
  bool isPlaylistSaved(String id) => state.isPlaylistSaved(id);

  Future<void> _ensureLoaded(MediaItemType type) async {
    if (state.loaded.contains(type) || _loading.contains(type)) return;
    if (!_library.hasMetadata) return;
    if (!state.isAuthenticated) {
      emit(state.copyWith(loaded: {...state.loaded, type}));
      return;
    }
    await _load(type);
  }

  /// Re-reads the saved IDs even when loaded; announces only if [notify] is
  /// true and the set differs. Used after writes whose effect is not inferable
  /// locally (e.g. creating a playlist).
  @override
  Future<void> refresh(MediaItemType type, {bool notify = true}) async {
    if (_loading.contains(type)) return;
    if (!_library.hasMetadata || !state.isAuthenticated) return;
    await _load(type, notify: notify);
  }

  Future<void> _load(MediaItemType type, {bool notify = true}) async {
    final generation = _generation;
    _loading.add(type);
    try {
      _applyLoaded(type, await _loadIds(type), generation, notify: notify);
    } catch (_) {
    } finally {
      _loading.remove(type);
    }
  }

  void _applyLoaded(
    MediaItemType type,
    Set<String> ids,
    int generation, {
    required bool notify,
  }) {
    if (generation != _generation) return;
    final previous = _snapshot[type];
    _snapshot[type] = ids;

    emit(state.withIds(type, ids).copyWith(loaded: {...state.loaded, type}));
    // No previous set means first read (warm-up): never announce it.
    if (notify && previous != null && !setEquals(previous, ids)) {
      _savedChanges.add(type);
    }
  }

  @override
  Future<void> toggleTrack(Track track) => _toggle(
    type: MediaItemType.track,
    id: track.id,
    save: () => _library.saveTrack(track.id),
    unsave: () => _library.unsaveTrack(track.id),
  );

  @override
  Future<void> toggleAlbum(Album album) => _toggle(
    type: MediaItemType.album,
    id: album.id,
    save: () => _library.saveAlbum(album.id),
    unsave: () => _library.unsaveAlbum(album.id),
  );

  @override
  Future<void> toggleArtist(Artist artist) => _toggle(
    type: MediaItemType.artist,
    id: artist.id,
    save: () => _library.saveArtist(artist.id),
    unsave: () => _library.unsaveArtist(artist.id),
  );

  @override
  Future<void> togglePlaylist(Playlist playlist) => _toggle(
    type: MediaItemType.playlist,
    id: playlist.id,
    save: () => _library.savePlaylist(playlist.id),
    unsave: () => _library.unsavePlaylist(playlist.id),
  );

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
      // Announce after the write lands: an earlier reload could read stale state.
      _snapshot[type] = optimistic;
      _savedChanges.add(type);
      // Saving a playlist may persist a copy under a different id: re-read.
      if (type == MediaItemType.playlist) {
        await _load(type);
      }
    } catch (e) {
      _snapshot[type] = previous;
      emit(state.withIds(type, previous));
      _notices.emit(Notice.error(e));
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

  /// Null on failure (announced on the notice bus); no event when the provider
  /// added nothing.
  @override
  Future<AddTracksResult?> addTrackToPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      final result = await _playlists.addTracks(playlistId, [trackId]);
      if (result.added > 0 && !_edits.isClosed) {
        _edits.add(PlaylistTracksChanged(playlistId, added: [trackId]));
      }
      return result;
    } catch (e) {
      _notices.emit(Notice.error(e));
      return null;
    }
  }

  /// False on failure (announced on the notice bus).
  @override
  Future<bool> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      await _playlists.removeTracks(playlistId, [trackId]);
      if (!_edits.isClosed) {
        _edits.add(PlaylistTracksChanged(playlistId, removed: [trackId]));
      }
      return true;
    } catch (e) {
      _notices.emit(Notice.error(e));
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _savedChanges.close();
    await _edits.close();
    return super.close();
  }
}
