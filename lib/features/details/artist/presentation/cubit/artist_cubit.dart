import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/utils/fetch_all_pages.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/features/details/artist/presentation/cubit/artist_state.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

class ArtistCubit extends SafeCubit<ArtistState> {
  final MediaRepository _media;
  final NoticeBus _notices;
  bool _isFetchingMoreTopTracks = false;
  bool _isFetchingMoreAlbums = false;
  bool _isFetchingMoreRelated = false;

  ArtistCubit(this._media, this._notices, Artist initialArtist)
    : super(ArtistState(artist: initialArtist));

  Future<void> loadArtist() async {
    if (!_media.hasMetadata) {
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
    fetchTopTracks(limit: 6);
    fetchAlbums(limit: 6);
    fetchRelated(limit: 6);
  }

  void _fetchFullArtist(String id) {
    try {
      _media
          .artist(id)
          .then((fullArtist) {
            emit(state.copyWith(artist: fullArtist));
          })
          .catchError((_) {});
    } catch (_) {}
  }

  void fetchTopTracks({int offset = 0, int limit = 6}) {
    emit(state.copyWith(topTracks: SectionState.loading(state.topTracks.data)));

    _media
        .artistTopTracks(state.artist.id, offset: offset, limit: limit)
        .then((tracks) {
          emit(state.copyWith(topTracks: SectionState.success(tracks)));
        })
        .catchError((Object e) {
          emit(
            state.copyWith(
              topTracks: SectionState.error(e, state.topTracks.data),
            ),
          );
          if (e.needsNotice) _notices.emit(Notice.error(e));
        });
  }

  Future<void> fetchMoreTopTracks({int limit = 6}) async {
    if (state.topTracks.isLoading || _isFetchingMoreTopTracks) return;
    final currentData = state.topTracks.data;
    if (currentData.items.length >= currentData.total) return;

    _isFetchingMoreTopTracks = true;
    emit(state.copyWith(topTracks: SectionState.loading(currentData)));

    try {
      final offset = currentData.items.length;
      final result = await _media.artistTopTracks(
        state.artist.id,
        offset: offset,
        limit: limit,
      );

      final combined = [...currentData.items, ...result.items];
      final updatedResult = PaginatedResult<Track>(
        items: combined,
        total: result.total,
        offset: offset,
        limit: limit,
      );

      emit(state.copyWith(topTracks: SectionState.success(updatedResult)));
    } catch (e) {
      emit(state.copyWith(topTracks: SectionState.error(e, currentData)));
      if (e.needsNotice) _notices.emit(Notice.error(e));
    } finally {
      _isFetchingMoreTopTracks = false;
    }
  }

  void fetchAlbums({int offset = 0, int limit = 6}) {
    emit(state.copyWith(albums: SectionState.loading(state.albums.data)));

    _media
        .artistAlbums(state.artist.id, offset: offset, limit: limit)
        .then((albums) {
          emit(state.copyWith(albums: SectionState.success(albums)));
        })
        .catchError((Object e) {
          emit(
            state.copyWith(albums: SectionState.error(e, state.albums.data)),
          );
          if (e.needsNotice) _notices.emit(Notice.error(e));
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
      final result = await _media.artistAlbums(
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
      if (e.needsNotice) _notices.emit(Notice.error(e));
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
      final result = await _media.artistRelated(
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
      if (e.needsNotice) _notices.emit(Notice.error(e));
    } finally {
      _isFetchingMoreRelated = false;
    }
  }

  void fetchRelated({int offset = 0, int limit = 6}) {
    emit(state.copyWith(related: SectionState.loading(state.related.data)));

    _media
        .artistRelated(state.artist.id, offset: offset, limit: limit)
        .then((related) {
          emit(state.copyWith(related: SectionState.success(related)));
        })
        .catchError((Object e) {
          emit(
            state.copyWith(related: SectionState.error(e, state.related.data)),
          );
          if (e.needsNotice) _notices.emit(Notice.error(e));
        });
  }

  PendingSource? pendingTopTracksSource() {
    final data = state.topTracks.data;
    if (data.items.length >= data.total) return null;
    final id = state.artist.id;
    return PendingSource(
      loader: (offset) => _media.artistTopTracks(id, offset: offset),
      nextOffset: data.items.length,
      total: data.total,
    );
  }

  Future<List<Track>?> loadAllTopTracks() {
    return fetchAllPages(
      (offset, limit) =>
          _media.artistTopTracks(state.artist.id, offset: offset, limit: limit),
    );
  }
}
