import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/data/exceptions/plugin_engine_exceptions.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class PlaylistCubit extends SafeCubit<PlaylistState> {
  final PluginEngine _pluginEngine;
  bool _isFetchingMoreTracks = false;

  PlaylistCubit(this._pluginEngine) : super(PlaylistInitialState());

  Future<void> loadPlaylist(Playlist playlist) async {
    if (!_pluginEngine.hasMetadata) {
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
      final fullPlaylist = await _pluginEngine.metadata.playlist.getPlaylist(
        playlist.id,
      );
      final result = await _pluginEngine.metadata.playlist.tracks(
        playlist.id,
        offset: 0,
        limit: 20,
      );
      emit(PlaylistLoadedState(playlist: fullPlaylist, tracks: result));
    } catch (e) {
      if (state is PlaylistLoadedState) {
        final currentState = state as PlaylistLoadedState;
        emit(currentState.copyWith(refreshError: e));
      } else {
        emit(PlaylistErrorState(error: e, playlist: playlist));
      }
    }
  }

  Future<void> loadMoreTracks() async {
    if (state is! PlaylistLoadedState || _isFetchingMoreTracks) return;
    final currentState = state as PlaylistLoadedState;
    if (!currentState.hasMoreTracks) return;

    _isFetchingMoreTracks = true;

    try {
      final offset = currentState.tracks.items.length;
      final result = await _pluginEngine.metadata.playlist.tracks(
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
      emit(currentState.copyWith(refreshError: e));
    } finally {
      _isFetchingMoreTracks = false;
    }
  }

  Future<void> toggleSave() async {
    if (state is! PlaylistLoadedState) return;
    final currentState = state as PlaylistLoadedState;

    try {
      final isSavedNow = !currentState.isSaved;
      if (isSavedNow) {
        await _pluginEngine.metadata.playlist.save(currentState.playlist.id);
      } else {
        await _pluginEngine.metadata.playlist.unsave(currentState.playlist.id);
      }
      emit(currentState.copyWith(isSaved: isSavedNow));
    } catch (_) {}
  }
}
