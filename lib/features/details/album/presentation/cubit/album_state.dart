import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
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

  AlbumLoadedState({
    required this.album,
    required this.tracks,
    this.isSaved = false,
  });

  @override
  MediaItemMetadata get metadata => MediaItemMetadata.from(album);
  bool get hasMoreTracks => tracks.items.length < tracks.total;

  AlbumLoadedState copyWith({
    Album? album,
    PaginatedResult<Track>? tracks,
    bool? isSaved,
  }) {
    return AlbumLoadedState(
      album: album ?? this.album,
      tracks: tracks ?? this.tracks,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class AlbumLoadMoreErrorState extends AlbumLoadedState {
  final Object error;

  AlbumLoadMoreErrorState({
    required super.album,
    required super.tracks,
    required super.isSaved,
    required this.error,
  });
}

class AlbumErrorState extends AlbumState {
  final Object error;
  final Album album;

  AlbumErrorState({required this.error, required this.album});

  @override
  MediaItemMetadata get metadata => MediaItemMetadata.from(album);
}
