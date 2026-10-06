part of 'user_cubit.dart';

/// The saved-membership facts and the save toggles (the hearts), as the pages
/// see them: any page needs to know "is this saved?" and to toggle it, because
/// the actions live in the search, the detail pages, the player and the track
/// sheet.
abstract interface class UserFavorites {
  bool isTrackSaved(String id);
  bool isAlbumSaved(String id);
  bool isArtistSaved(String id);
  bool isPlaylistSaved(String id);
  Future<void> toggleTrack(Track track);
  Future<void> toggleAlbum(Album album);
  Future<void> toggleArtist(Artist artist);
  Future<void> togglePlaylist(Playlist playlist);
}
