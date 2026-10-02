import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

/// Data access for the provider search.
class SearchRepository {
  SearchRepository(this._engine);

  final MetadataPluginEngine _engine;

  bool get hasMetadata => _engine.hasMetadata;

  Future<List<SearchCategory>> chips() => _engine.metadata.search.chips();

  Future<SearchResponse> all(String query) => _engine.metadata.search.all(query);

  Future<PaginatedResult<Track>> tracks(
    String query, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.search.tracks(query, offset: offset, limit: limit);

  Future<PaginatedResult<Album>> albums(
    String query, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.search.albums(query, offset: offset, limit: limit);

  Future<PaginatedResult<Artist>> artists(
    String query, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.search.artists(query, offset: offset, limit: limit);

  Future<PaginatedResult<Playlist>> playlists(
    String query, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.search.playlists(query, offset: offset, limit: limit);
}
