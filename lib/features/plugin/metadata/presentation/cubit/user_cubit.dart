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

/// Outcome of an interactive sign-in attempt.
///
/// [cancelled] and [failed] are deliberately distinct: cancelling the provider
/// form is a normal user choice that must stay silent, while a failure (wrong
/// token, offline) deserves feedback.
enum AuthResult { authenticated, cancelled, failed }

/// Single source of truth for the signed-in user: the account identity, the
/// global index of their saved media, and the playlist edits.
///
/// It observes the repositories (the data layer). Pages read the whole state
/// through `BlocBuilder<UserCubit, UserState>`; the page-loading cubits depend
/// only on the facet they need ([UserSession], [UserFavorites],
/// [UserSavedMediaIndex] or [UserPlaylistEdits]).
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

  /// Last settled set per type: lets [_applyLoaded] tell a real change from the
  /// warm-up (first read) and from a refresh that returned the same IDs.
  final Map<MediaItemType, Set<String>> _snapshot = {};

  /// Invalidates in-flight loads on [_resetIndex], so a load started under the
  /// old account can never repopulate the index of the new one.
  int _generation = 0;

  @override
  bool get isAuthenticated => state.isAuthenticated;

  @override
  String? get userId => state.userId;

  /// Emits the sign-in state whenever it changes; a repeated value is dropped.
  ///
  /// A broadcast stream does not replay the current value: consumers read
  /// [isAuthenticated] for the initial state and subscribe for the changes.
  @override
  Stream<bool> get authenticationChanges =>
      stream.map((state) => state.isAuthenticated).distinct();

  /// Emits a type only for a genuine change (a successful toggle, or a refresh
  /// returning a different set), never for the warm-up or an identical refetch.
  @override
  Stream<MediaItemType> get savedChanges => _savedChanges.stream;

  @override
  Stream<PlaylistTracksChanged> get playlistEdits => _edits.stream;

  /// Resolves the sign-in flag locally, then emits at once with the identity
  /// last known; the provider identity is refreshed in the background and the
  /// saved index warms up with the account.
  ///
  /// Reading the identity needs a provider round-trip that can be slow or fail
  /// (offline boot). Emitting the cached value first keeps the app usable and
  /// avoids blocking `initialize()` (and therefore `runApp`) on the network.
  Future<void> initialize() async {
    if (!_account.hasMetadata) return;
    var isAuthenticated = false;
    try {
      isAuthenticated = await _account.isAuthenticated();
    } catch (_) {
      // Without the local flag we cannot claim a session; stay signed out.
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

  /// Resolves the identity from the provider and updates the state if it changed.
  Future<void> _refreshIdentity() async {
    try {
      final userId = await _account.resolveUserId();
      if (isClosed || userId == null || userId == state.userId) return;
      emit(state.copyWith(userId: userId));
    } catch (_) {
      // The cached identity (if any) stays authoritative until the next attempt.
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
      // Keep the signed-out state even if the provider logout fails.
    }
    _resetIndex();
    emit(const UserState());
  }

  /// Drops the cached IDs, e.g. so the next access reloads them, keeping the
  /// sign-in state: the reset of the index is not a change a listing has to
  /// react to, and it must never sign the user out.
  ///
  /// The in-flight markers are dropped too, so a load started under the
  /// previous account does not block the new account's warm-up; its result is
  /// discarded by [_applyLoaded]'s generation check.
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

  /// Loads the saved index in the background: the saved set belongs to the
  /// account, so it loads with it instead of being requested by each page.
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

  /// Re-reads the saved IDs of [type] even when already loaded, announcing a
  /// change only if [notify] is true and the returned set differs from the last
  /// one.
  ///
  /// Used after a write whose effect on the saved set is not inferable locally,
  /// such as creating a playlist; a silent refresh is used by pull-to-refresh,
  /// which reloads the listing explicitly.
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
      // Background load: stays silent and retries on the next access.
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
    // A missing previous set means this is the first read of the type: the
    // warm-up must not be announced as a change.
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
      _savedChanges.add(type);
      // Saving a playlist may persist a different id (a copy), so the requested
      // id is not authoritative: re-read the library and settle the set.
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

  /// Adds one track, returning what the provider changed; a failure is
  /// announced on the notice bus and returns null.
  ///
  /// Announces the change only when the provider added something: an
  /// already-present track changes nothing, so there is nothing to announce.
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

  /// Removes one track, returning whether the write landed; a failure is
  /// announced on the notice bus and returns false.
  ///
  /// A removal never touches the saved sets (playlist membership is not a
  /// save), so only the edits channel is announced.
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
