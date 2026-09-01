import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class PlaylistCubit extends SafeCubit<PlaylistState> {
  final MetadataPluginEngine _pluginEngine;
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
      final result = await _pluginEngine.metadata.playlist.tracks(
        playlist.id,
        offset: 0,
        limit: 20,
      );
      emit(PlaylistLoadedState(playlist: playlist, tracks: result));
    } catch (e) {
      emit(PlaylistErrorState(error: e, playlist: playlist));
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
          isSaved: currentState.isSaved,
        ),
      );
    }

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
      emit(
        PlaylistLoadMoreErrorState(
          playlist: currentState.playlist,
          tracks: currentState.tracks,
          isSaved: currentState.isSaved,
          error: e,
        ),
      );
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
