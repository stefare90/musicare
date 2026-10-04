import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

/// Ownership of a playlist: the provider reports its creator in `owner`, so a
/// playlist belongs to the signed-in user when the two ids match.
extension PlaylistOwnership on Playlist {
  bool isOwnedBy(String? userId) => userId != null && owner.id == userId;
}
