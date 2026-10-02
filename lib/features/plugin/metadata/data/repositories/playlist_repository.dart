import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

/// Data access for playlist writes: creation (resolving the signed-in user)
/// and adding tracks. The callers orchestrate the flows and surface errors.
class PlaylistRepository {
  PlaylistRepository(this._engine);

  final MetadataPluginEngine _engine;

  bool get hasMetadata => _engine.hasMetadata;

  Future<Playlist?> createPlaylist(
    String name, {
    String? description,
    bool isPublic = false,
  }) async {
    final me = await _engine.metadata.user.me();
    final userId = me['user_id'] as String?;
    if (userId == null) return null;

    return _engine.metadata.playlist.createPlaylist(
      userId,
      name,
      description: description,
      public_: isPublic,
    );
  }

  Future<void> addTracks(String playlistId, List<String> trackIds) =>
      _engine.metadata.playlist.addTracks(playlistId, trackIds);
}
