import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class AlbumCubit extends SafeCubit<AlbumState> {
  final MetadataPluginEngine _pluginEngine;
  bool _isFetchingMoreTracks = false;

  AlbumCubit(this._pluginEngine) : super(AlbumInitialState());

  Future<void> loadAlbum(Album album) async {
    if (!_pluginEngine.hasMetadata) {
      emit(AlbumErrorState(error: PluginNotLoadedException(), album: album));
      return;
    }

    if (state is! AlbumLoadedState) {
      emit(AlbumLoadingState(album: album));
    }

    try {
      final result = await _pluginEngine.metadata.album.tracks(
        album.id,
        offset: 0,
        limit: 20,
      );

      final Album fullAlbum = result.items.isNotEmpty
          ? result.items.first.album
          : album;

      emit(AlbumLoadedState(album: fullAlbum, tracks: result));
    } catch (e) {
      emit(AlbumErrorState(error: e, album: album));
    }
  }

  Future<void> loadMoreTracks() async {
    if (state is! AlbumLoadedState || _isFetchingMoreTracks) return;
    final currentState = state as AlbumLoadedState;
    if (!currentState.hasMoreTracks) return;

    _isFetchingMoreTracks = true;

    if (state is AlbumLoadMoreErrorState) {
      emit(
        AlbumLoadedState(
          album: currentState.album,
          tracks: currentState.tracks,
          isSaved: currentState.isSaved,
        ),
      );
    }

    try {
      final offset = currentState.tracks.items.length;
      final result = await _pluginEngine.metadata.album.tracks(
        currentState.album.id,
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
        AlbumLoadMoreErrorState(
          album: currentState.album,
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
    if (state is! AlbumLoadedState) return;
    final currentState = state as AlbumLoadedState;
    try {
      final isSavedNow = !currentState.isSaved;
      if (isSavedNow) {
        await _pluginEngine.metadata.album.save([currentState.album.id]);
      } else {
        await _pluginEngine.metadata.album.unsave([currentState.album.id]);
      }
      emit(currentState.copyWith(isSaved: isSavedNow));
    } catch (_) {}
  }
}
