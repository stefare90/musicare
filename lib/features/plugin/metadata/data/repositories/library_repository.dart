import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class LibraryRepository {
  LibraryRepository(this._engine);

  final MetadataPluginEngine _engine;

  bool get hasMetadata => _engine.hasMetadata;

  Future<PaginatedResult<Playlist>> savedPlaylists({
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.user.savedPlaylists(offset: offset, limit: limit);

  Future<PaginatedResult<Album>> savedAlbums({
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.user.savedAlbums(offset: offset, limit: limit);

  Future<PaginatedResult<Artist>> savedArtists({
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.user.savedArtists(offset: offset, limit: limit);

  Future<PaginatedResult<Track>> savedTracks({
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.user.savedTracks(offset: offset, limit: limit);

  Future<void> saveTrack(String id) => _engine.metadata.track.save([id]);

  Future<void> unsaveTrack(String id) => _engine.metadata.track.unsave([id]);

  Future<void> saveAlbum(String id) => _engine.metadata.album.save([id]);

  Future<void> unsaveAlbum(String id) => _engine.metadata.album.unsave([id]);

  Future<void> saveArtist(String id) => _engine.metadata.artist.save([id]);

  Future<void> unsaveArtist(String id) => _engine.metadata.artist.unsave([id]);

  Future<void> savePlaylist(String id) => _engine.metadata.playlist.save(id);

  Future<void> unsavePlaylist(String id) =>
      _engine.metadata.playlist.unsave(id);
}
