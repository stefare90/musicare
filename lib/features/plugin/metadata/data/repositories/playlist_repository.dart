import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

/// Data access for playlist writes: creation (resolving the signed-in user),
/// adding/removing tracks and deletion. Callers orchestrate the flows and
/// surface errors.
class PlaylistRepository {
  PlaylistRepository(this._engine);

  final MetadataPluginEngine _engine;

  bool get hasMetadata => _engine.hasMetadata;

  /// Creates a playlist for the signed-in user.
  ///
  /// Throws [MetadataAuthRequiredException] when the provider reports no user,
  /// so callers surface a sign-in prompt instead of a silent no-op.
  Future<Playlist?> createPlaylist(
    String name, {
    String? description,
    bool isPublic = false,
  }) async {
    final me = await _engine.metadata.user.me();
    final userId = me['user_id'] as String?;
    if (userId == null) throw const MetadataAuthRequiredException('');

    return _engine.metadata.playlist.createPlaylist(
      userId,
      name,
      description: description,
      public_: isPublic,
    );
  }

  Future<AddTracksResult> addTracks(String playlistId, List<String> trackIds) =>
      _engine.metadata.playlist.addTracks(playlistId, trackIds);

  Future<void> removeTracks(String playlistId, List<String> trackIds) =>
      _engine.metadata.playlist.removeTracks(playlistId, trackIds);

  Future<void> deletePlaylist(String playlistId) =>
      _engine.metadata.playlist.deletePlaylist(playlistId);
}
