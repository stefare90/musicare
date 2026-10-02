import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

/// Data access for the home browse sections.
class BrowseRepository {
  BrowseRepository(this._engine);

  final MetadataPluginEngine _engine;

  bool get hasMetadata => _engine.hasMetadata;

  Future<PaginatedResult<Section>> sections({int offset = 0, int limit = 20}) =>
      _engine.metadata.browse.sections(offset: offset, limit: limit);

  Future<PaginatedResult<MediaItem>> sectionItems(
    String id, {
    int offset = 0,
    int limit = 20,
  }) =>
      _engine.metadata.browse.sectionItems(id, offset: offset, limit: limit);
}
