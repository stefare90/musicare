import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/models/media_item_metadata.dart';

abstract class AlbumState {
  MediaItemMetadata? get metadata;
}

class AlbumInitialState extends AlbumState {
  @override
  MediaItemMetadata? get metadata => null;
}

class AlbumLoadingState extends AlbumState {
  final Album album;
  AlbumLoadingState({required this.album});

  @override
  MediaItemMetadata get metadata => MediaItemMetadata.from(album);
}

class AlbumLoadedState extends AlbumState {
  final Album album;
  final PaginatedResult<Track> tracks;
  final bool isSaved;
  final Object? refreshError;

  AlbumLoadedState({
    required this.album,
    required this.tracks,
    this.isSaved = false,
    this.refreshError,
  });

  @override
  MediaItemMetadata get metadata => MediaItemMetadata.from(album);
  bool get hasMoreTracks => tracks.items.length < tracks.total;

  AlbumLoadedState copyWith({
    Album? album,
    PaginatedResult<Track>? tracks,
    bool? isSaved,
    Object? refreshError,
  }) {
    return AlbumLoadedState(
      album: album ?? this.album,
      tracks: tracks ?? this.tracks,
      isSaved: isSaved ?? this.isSaved,
      refreshError: refreshError,
    );
  }
}

class AlbumErrorState extends AlbumState {
  final Object error;
  final Album album;

  AlbumErrorState({required this.error, required this.album});

  @override
  MediaItemMetadata get metadata => MediaItemMetadata.from(album);
}
