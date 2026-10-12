import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_state.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

class AlbumCubit extends SafeCubit<AlbumState> {
  final MediaRepository _media;
  final NoticeBus _notices;
  bool _isFetchingMoreTracks = false;

  AlbumCubit(this._media, this._notices) : super(AlbumInitialState());

  Future<void> loadAlbum(Album album) async {
    if (!_media.hasMetadata) {
      emit(AlbumErrorState(error: PluginNotLoadedException(), album: album));
      return;
    }

    if (state is! AlbumLoadedState) {
      emit(AlbumLoadingState(album: album));
    }

    try {
      final result = await _media.albumTracks(
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
      if (e.needsNotice) _notices.emit(Notice.error(e));
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
        ),
      );
    }

    try {
      final offset = currentState.tracks.items.length;
      final result = await _media.albumTracks(
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
          error: e,
        ),
      );
      if (e.needsNotice) _notices.emit(Notice.error(e));
    } finally {
      _isFetchingMoreTracks = false;
    }
  }

  PendingSource? pendingSource() {
    final current = state;
    if (current is! AlbumLoadedState) return null;
    if (!current.hasMoreTracks) return null;
    final id = current.album.id;
    return PendingSource(
      loader: (offset) => _media.albumTracks(id, offset: offset),
      nextOffset: current.tracks.items.length,
      total: current.tracks.total,
    );
  }
}
