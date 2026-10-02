import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

/// Which media items the signed-in user has saved.
///
/// IDs only: the paginated lists live in the page cubits, while this is the
/// small global index that answers "is this saved?" from any page. [loaded]
/// tracks which types have been fetched, so [withIds] never conflates "not
/// saved" with "not loaded yet".
class SavedMediaState {
  final Set<String> trackIds;
  final Set<String> albumIds;
  final Set<String> artistIds;
  final Set<String> playlistIds;
  final Set<MediaItemType> loaded;

  const SavedMediaState({
    this.trackIds = const {},
    this.albumIds = const {},
    this.artistIds = const {},
    this.playlistIds = const {},
    this.loaded = const {},
  });

  Iterable<String> idsOf(MediaItemType type) => switch (type) {
    MediaItemType.track => trackIds,
    MediaItemType.album => albumIds,
    MediaItemType.artist => artistIds,
    MediaItemType.playlist => playlistIds,
  };

  bool isSaved(MediaItemType type, String id) => idsOf(type).contains(id);

  bool isTrackSaved(String id) => trackIds.contains(id);
  bool isAlbumSaved(String id) => albumIds.contains(id);
  bool isArtistSaved(String id) => artistIds.contains(id);
  bool isPlaylistSaved(String id) => playlistIds.contains(id);

  SavedMediaState copyWith({
    Set<String>? trackIds,
    Set<String>? albumIds,
    Set<String>? artistIds,
    Set<String>? playlistIds,
    Set<MediaItemType>? loaded,
  }) {
    return SavedMediaState(
      trackIds: trackIds ?? this.trackIds,
      albumIds: albumIds ?? this.albumIds,
      artistIds: artistIds ?? this.artistIds,
      playlistIds: playlistIds ?? this.playlistIds,
      loaded: loaded ?? this.loaded,
    );
  }

  SavedMediaState withIds(MediaItemType type, Set<String> ids) =>
      switch (type) {
        MediaItemType.track => copyWith(trackIds: ids),
        MediaItemType.album => copyWith(albumIds: ids),
        MediaItemType.artist => copyWith(artistIds: ids),
        MediaItemType.playlist => copyWith(playlistIds: ids),
      };
}
