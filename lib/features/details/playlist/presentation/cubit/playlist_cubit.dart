import 'dart:async';
import 'dart:math';

import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

class PlaylistCubit extends SafeCubit<PlaylistState> {
  final MediaRepository _media;
  final PlaylistRepository _playlist;
  final NoticeBus _notices;
  final UserSavedMediaIndex _savedMedia;
  final UserPlaylistEdits _edits;
  StreamSubscription<PlaylistTracksChanged>? _editsSubscription;
  bool _isFetchingMoreTracks = false;

  PlaylistCubit(
    this._media,
    this._playlist,
    this._notices, {
    required this._savedMedia,
    required this._edits,
  }) : super(PlaylistInitialState()) {
    _editsSubscription = _edits.playlistEdits
        .where(_isRelevant)
        .listen((_) => unawaited(_reloadWindow()));
  }

  /// True when [event] describes a change the loaded window does not reflect
  /// yet; own actions are already applied locally and need no refetch.
  bool _isRelevant(PlaylistTracksChanged event) {
    final current = state;
    if (current is! PlaylistLoadedState) return false;
    if (current.playlist.id != event.playlistId) return false;
    final ids = current.tracks.items.map((track) => track.id).toSet();
    return event.added.any((id) => !ids.contains(id)) ||
        event.removed.any((id) => ids.contains(id));
  }

  /// Re-reads the loaded window from the start, keeping its size: the provider
  /// appends at the tail, so a local insert would break the offset. A failed
  /// reload keeps the current state.
  Future<void> _reloadWindow() async {
    final current = state;
    if (current is! PlaylistLoadedState) return;
    final limit = max(current.tracks.items.length, 20);
    try {
      final result = await _media.playlistTracks(
        current.playlist.id,
        offset: 0,
        limit: limit,
      );
      if (isClosed) return;
      final reloaded = state;
      if (reloaded is! PlaylistLoadedState) return;
      if (reloaded.playlist.id != current.playlist.id) return;
      emit(reloaded.copyWith(tracks: result));
    } catch (e) {
      if (e.needsNotice) _notices.emit(Notice.error(e));
    }
  }

  Future<void> loadPlaylist(Playlist playlist) async {
    if (!_media.hasMetadata) {
      emit(
        PlaylistErrorState(
          error: PluginNotLoadedException(),
          playlist: playlist,
        ),
      );
      return;
    }

    if (state is! PlaylistLoadedState) {
      emit(PlaylistLoadingState(playlist: playlist));
    }

    try {
      final result = await _media.playlistTracks(
        playlist.id,
        offset: 0,
        limit: 20,
      );
      emit(PlaylistLoadedState(playlist: playlist, tracks: result));
    } catch (e) {
      emit(PlaylistErrorState(error: e, playlist: playlist));
      if (e.needsNotice) _notices.emit(Notice.error(e));
    }
  }

  Future<bool> removeTrack(Track track) async {
    final current = state;
    if (current is! PlaylistLoadedState) return false;
    final previous = current.tracks;
    final remaining = previous.items
        .where((item) => item.id != track.id)
        .toList();
    if (remaining.length == previous.items.length) return false;

    emit(
      current.copyWith(
        tracks: PaginatedResult<Track>(
          items: remaining,
          total: previous.total - 1,
          offset: previous.offset,
          limit: previous.limit,
        ),
      ),
    );

    // The write and its announcement belong to the facet; the own event finds
    // the track already removed here and is ignored.
    if (await _edits.removeTrackFromPlaylist(current.playlist.id, track.id)) {
      return true;
    }
    emit(current.copyWith(tracks: previous));
    return false;
  }

  Future<bool> deletePlaylist() async {
    final current = state;
    if (current is! PlaylistLoadedState) return false;
    try {
      await _playlist.deletePlaylist(current.playlist.id);
      await _savedMedia.refresh(MediaItemType.playlist);
      return true;
    } catch (e) {
      _notices.emit(Notice.error(e));
      return false;
    }
  }

  Future<void> loadMoreTracks() async {
    if (state is! PlaylistLoadedState || _isFetchingMoreTracks) return;
    final currentState = state as PlaylistLoadedState;
    if (!currentState.hasMoreTracks) return;

    _isFetchingMoreTracks = true;

    if (state is PlaylistLoadMoreErrorState) {
      emit(
        PlaylistLoadedState(
          playlist: currentState.playlist,
          tracks: currentState.tracks,
        ),
      );
    }

    try {
      final offset = currentState.tracks.items.length;
      final result = await _media.playlistTracks(
        currentState.playlist.id,
        offset: offset,
        limit: 20,
      );

      final combinedTracks = [...currentState.tracks.items, ...result.items];
      final updatedResult = PaginatedResult<Track>(
        items: combinedTracks,
        total: result.total,
        offset: offset,
        limit: 20,
      );

      emit(currentState.copyWith(tracks: updatedResult));
    } catch (e) {
      emit(
        PlaylistLoadMoreErrorState(
          playlist: currentState.playlist,
          tracks: currentState.tracks,
          error: e,
        ),
      );
      if (e.needsNotice) _notices.emit(Notice.error(e));
    } finally {
      _isFetchingMoreTracks = false;
    }
  }

  @override
  Future<void> close() async {
    await _editsSubscription?.cancel();
    return super.close();
  }
}
