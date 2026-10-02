import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

class PlaylistCubit extends SafeCubit<PlaylistState> {
  final MediaRepository _media;
  final NoticeBus _notices;
  bool _isFetchingMoreTracks = false;

  PlaylistCubit(this._media, this._notices)
    : super(PlaylistInitialState());

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
      if (e.needsNotice) _notices.emit(e);
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
      if (e.needsNotice) _notices.emit(e);
    } finally {
      _isFetchingMoreTracks = false;
    }
  }
}
