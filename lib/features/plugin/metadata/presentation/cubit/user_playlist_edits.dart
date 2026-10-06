part of 'user_cubit.dart';

/// A user-driven change to the tracks of one playlist.
///
/// It carries both sides because the detail page tells its own actions (already
/// applied to its list, to ignore) from external ones (to refetch) by checking
/// whether its loaded window already reflects each id: without [removed], an
/// external removal would stay invisible.
class PlaylistTracksChanged {
  final String playlistId;

  /// The added ids (already-present ones excluded, per [AddTracksResult]).
  final List<String> added;

  /// The removed ids.
  final List<String> removed;

  const PlaylistTracksChanged(
    this.playlistId, {
    this.added = const [],
    this.removed = const [],
  });
}

/// The playlist writes plus their events, as the editing cubits see them.
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
