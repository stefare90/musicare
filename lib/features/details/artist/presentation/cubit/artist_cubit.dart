import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/features/details/artist/presentation/cubit/artist_state.dart';
import 'package:music_are/features/plugin/data/exceptions/plugin_engine_exceptions.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class ArtistCubit extends SafeCubit<ArtistState> {
  final PluginEngine _pluginEngine;
  bool _isFetchingMoreAlbums = false;
  bool _isFetchingMoreRelated = false;

  ArtistCubit(this._pluginEngine, Artist initialArtist)
    : super(ArtistState(artist: initialArtist));

  Future<void> loadArtist() async {
    if (!_pluginEngine.hasMetadata) {
      final error = PluginNotLoadedException();
      emit(
        state.copyWith(
          topTracks: SectionState.error(error, state.topTracks.data),
          albums: SectionState.error(error, state.albums.data),
          related: SectionState.error(error, state.related.data),
        ),
      );
      return;
    }

    _fetchFullArtist(state.artist.id);
    fetchTopTracks();
    fetchAlbums(limit: 6);
    fetchRelated(limit: 6);
  }

  void _fetchFullArtist(String id) {
    try {
      _pluginEngine.metadata.artist
          .getArtist(id)
          .then((fullArtist) {
            emit(state.copyWith(artist: fullArtist));
          })
          .catchError((_) {});
    } catch (_) {}
  }

  void fetchTopTracks() {
    emit(state.copyWith(topTracks: SectionState.loading(state.topTracks.data)));

    _pluginEngine.metadata.artist
        .topTracks(state.artist.id, offset: 0, limit: 10)
        .then((tracks) {
          emit(state.copyWith(topTracks: SectionState.success(tracks)));
        })
        .catchError((e) {
          emit(
            state.copyWith(
              topTracks: SectionState.error(e, state.topTracks.data),
            ),
          );
        });
  }

  void fetchAlbums({int offset = 0, int limit = 6}) {
    emit(state.copyWith(albums: SectionState.loading(state.albums.data)));

    _pluginEngine.metadata.artist
        .albums(state.artist.id, offset: offset, limit: limit)
        .then((albums) {
          emit(state.copyWith(albums: SectionState.success(albums)));
        })
        .catchError((e) {
          emit(
            state.copyWith(albums: SectionState.error(e, state.albums.data)),
          );
        });
  }

  Future<void> fetchMoreAlbums({int limit = 6}) async {
    if (state.albums.isLoading || _isFetchingMoreAlbums) return;
    final currentData = state.albums.data;
    if (currentData.items.length >= currentData.total) return;

    _isFetchingMoreAlbums = true;
    emit(state.copyWith(albums: SectionState.loading(currentData)));

    try {
      final offset = currentData.items.length;
      final result = await _pluginEngine.metadata.artist.albums(
        state.artist.id,
        offset: offset,
        limit: limit,
      );

      final combined = [...currentData.items, ...result.items];
      final updatedResult = PaginatedResult<Album>(
        items: combined,
        total: result.total,
        offset: offset,
        limit: limit,
      );

      emit(state.copyWith(albums: SectionState.success(updatedResult)));
    } catch (e) {
      emit(state.copyWith(albums: SectionState.error(e, currentData)));
    } finally {
      _isFetchingMoreAlbums = false;
    }
  }

  Future<void> fetchMoreRelated({int limit = 6}) async {
    if (state.related.isLoading || _isFetchingMoreRelated) return;
    final currentData = state.related.data;
    if (currentData.items.length >= currentData.total) return;

    _isFetchingMoreRelated = true;
    emit(state.copyWith(related: SectionState.loading(currentData)));

    try {
      final offset = currentData.items.length;
      final result = await _pluginEngine.metadata.artist.related(
        state.artist.id,
        offset: offset,
        limit: limit,
      );

      final combined = [...currentData.items, ...result.items];
      final updatedResult = PaginatedResult<Artist>(
        items: combined,
        total: result.total,
        offset: offset,
        limit: limit,
      );

      emit(state.copyWith(related: SectionState.success(updatedResult)));
    } catch (e) {
      emit(state.copyWith(related: SectionState.error(e, currentData)));
    } finally {
      _isFetchingMoreRelated = false;
    }
  }

  void fetchRelated({int offset = 0, int limit = 6}) {
    emit(state.copyWith(related: SectionState.loading(state.related.data)));

    _pluginEngine.metadata.artist
        .related(state.artist.id, offset: offset, limit: limit)
        .then((related) {
          emit(state.copyWith(related: SectionState.success(related)));
        })
        .catchError((e) {
          emit(
            state.copyWith(related: SectionState.error(e, state.related.data)),
          );
        });
  }

  Future<void> toggleSave() async {
    try {
      final isSavedNow = !state.isSaved;
      if (isSavedNow) {
        await _pluginEngine.metadata.artist.save([state.artist.id]);
      } else {
        await _pluginEngine.metadata.artist.unsave([state.artist.id]);
      }
      emit(state.copyWith(isSaved: isSavedNow));
    } catch (_) {}
  }
}
