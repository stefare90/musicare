part of 'user_cubit.dart';

/// The signed-in user: the account identity plus the global index of their
/// saved media.
///
/// IDs only: the paginated lists live in the page cubits, while this is the
/// small global state that answers "is this saved?" from any page. [loaded]
/// tracks which types have been fetched, so [withIds] never conflates "not
/// saved" with "not loaded yet".
class UserState {
  final bool isAuthenticated;
  final String? userId;
  final Set<String> trackIds;
  final Set<String> albumIds;
  final Set<String> artistIds;
  final Set<String> playlistIds;
  final Set<MediaItemType> loaded;

  const UserState({
    this.isAuthenticated = false,
    this.userId,
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

  UserState copyWith({
    bool? isAuthenticated,
    String? userId,
    Set<String>? trackIds,
    Set<String>? albumIds,
    Set<String>? artistIds,
    Set<String>? playlistIds,
    Set<MediaItemType>? loaded,
  }) {
    return UserState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      trackIds: trackIds ?? this.trackIds,
      albumIds: albumIds ?? this.albumIds,
      artistIds: artistIds ?? this.artistIds,
      playlistIds: playlistIds ?? this.playlistIds,
      loaded: loaded ?? this.loaded,
    );
  }

  UserState withIds(MediaItemType type, Set<String> ids) => switch (type) {
    MediaItemType.track => copyWith(trackIds: ids),
    MediaItemType.album => copyWith(albumIds: ids),
    MediaItemType.artist => copyWith(artistIds: ids),
    MediaItemType.playlist => copyWith(playlistIds: ids),
  };
}
