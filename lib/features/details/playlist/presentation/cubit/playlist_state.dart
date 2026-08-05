import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/models/media_item_metadata.dart';

abstract class PlaylistState {
  MediaItemMetadata? get metadata;
}

class PlaylistInitialState extends PlaylistState {
  @override
  MediaItemMetadata? get metadata => null;
}

class PlaylistLoadingState extends PlaylistState {
  final Playlist playlist;
  PlaylistLoadingState({required this.playlist});

  @override
  MediaItemMetadata get metadata => MediaItemMetadata.from(playlist);
}

class PlaylistLoadedState extends PlaylistState {
  final Playlist playlist;
  final PaginatedResult<Track> tracks;
  final bool isSaved;
  final Object? refreshError;

  PlaylistLoadedState({
    required this.playlist,
    required this.tracks,
    this.isSaved = false,
    this.refreshError,
  });

  @override
  MediaItemMetadata get metadata => MediaItemMetadata.from(playlist);
  bool get hasMoreTracks => tracks.items.length < tracks.total;

  PlaylistLoadedState copyWith({
    Playlist? playlist,
    PaginatedResult<Track>? tracks,
    bool? isSaved,
    Object? refreshError,
  }) {
    return PlaylistLoadedState(
      playlist: playlist ?? this.playlist,
      tracks: tracks ?? this.tracks,
      isSaved: isSaved ?? this.isSaved,
      refreshError: refreshError,
    );
  }
}

class PlaylistErrorState extends PlaylistState {
  final Object error;
  final Playlist playlist;

  PlaylistErrorState({required this.error, required this.playlist});

  @override
  MediaItemMetadata get metadata => MediaItemMetadata.from(playlist);
}
