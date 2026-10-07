import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

extension PlaylistOwnership on Playlist {
  bool isOwnedBy(String? userId) => userId != null && owner.id == userId;
}
