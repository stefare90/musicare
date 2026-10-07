part of 'user_cubit.dart';

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
