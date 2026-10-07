import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class MediaRepository {
  MediaRepository(this._engine);

  final MetadataPluginEngine _engine;

  bool get hasMetadata => _engine.hasMetadata;

  Future<PaginatedResult<Track>> albumTracks(
    String id, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.album.tracks(id, offset: offset, limit: limit);

  Future<Artist> artist(String id) => _engine.metadata.artist.getArtist(id);

  Future<PaginatedResult<Track>> artistTopTracks(
    String id, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.artist.topTracks(id, offset: offset, limit: limit);

  Future<PaginatedResult<Album>> artistAlbums(
    String id, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.artist.albums(id, offset: offset, limit: limit);

  Future<PaginatedResult<Artist>> artistRelated(
    String id, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.artist.related(id, offset: offset, limit: limit);

  Future<PaginatedResult<Track>> playlistTracks(
    String id, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.playlist.tracks(id, offset: offset, limit: limit);
}
