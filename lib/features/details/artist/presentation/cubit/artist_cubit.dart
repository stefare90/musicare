import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/features/details/artist/presentation/cubit/artist_state.dart';
import 'package:music_are/features/plugin/data/exceptions/plugin_engine_exceptions.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';

class ArtistCubit extends SafeCubit<ArtistState> {
  final PluginEngine _pluginEngine;

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
    fetchAlbums();
    fetchRelated();
  }

  void _fetchFullArtist(String id) {
    _pluginEngine.metadata.artist
        .getArtist(id)
        .then((fullArtist) {
          emit(state.copyWith(artist: fullArtist));
        })
        .catchError((_) {});
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

  void fetchAlbums() {
    emit(state.copyWith(albums: SectionState.loading(state.albums.data)));

    _pluginEngine.metadata.artist
        .albums(state.artist.id, offset: 0, limit: 10)
        .then((albums) {
          emit(state.copyWith(albums: SectionState.success(albums)));
        })
        .catchError((e) {
          emit(
            state.copyWith(albums: SectionState.error(e, state.albums.data)),
          );
        });
  }

  void fetchRelated() {
    emit(state.copyWith(related: SectionState.loading(state.related.data)));

    _pluginEngine.metadata.artist
        .related(state.artist.id, offset: 0, limit: 10)
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
