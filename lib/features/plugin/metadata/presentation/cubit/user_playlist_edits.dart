part of 'user_cubit.dart';

/// Carries both sides because the detail page tells its own actions (already
/// applied, to ignore) from external ones (to refetch): without [removed],
/// an external removal would stay invisible.
class PlaylistTracksChanged {
  final String playlistId;

  /// The added ids (already-present ones excluded, per [AddTracksResult]).
  final List<String> added;

  final List<String> removed;

  const PlaylistTracksChanged(
    this.playlistId, {
    this.added = const [],
    this.removed = const [],
  });
}

abstract interface class UserPlaylistEdits {
  /// Emits one event per successful write that changed the playlist.
  Stream<PlaylistTracksChanged> get playlistEdits;

  /// Adds one track, returning what the provider changed; null on failure
  /// (announced on the notice bus).
  Future<AddTracksResult?> addTrackToPlaylist(
    String playlistId,
    String trackId,
  );

  /// Removes one track, returning whether the write landed; a failure is
  /// announced on the notice bus.
  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId);
}
