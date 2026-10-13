import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:share_plus/share_plus.dart';

abstract class ShareActions {
  static String albumText(Album album) =>
      _withLink(_titled(album.name, _names(album.artists)), album.externalUri);

  static String artistText(Artist artist) =>
      _withLink(artist.name, artist.externalUri);

  static String playlistText(Playlist playlist) =>
      _withLink(playlist.name, playlist.externalUri);

  static String trackText(Track track) =>
      _withLink(_titled(track.name, _names(track.artists)), track.externalUri);

  static Future<void> shareAlbum(Album album) => _share(albumText(album));

  static Future<void> shareArtist(Artist artist) => _share(artistText(artist));

  static Future<void> sharePlaylist(Playlist playlist) =>
      _share(playlistText(playlist));

  static Future<void> shareTrack(Track track) => _share(trackText(track));

  static String _titled(String name, String artists) =>
      artists.isEmpty ? name : '$name - $artists';

  static String _names(List<Artist> artists) =>
      artists.map((artist) => artist.name).join(', ');

  static String _withLink(String head, String uri) =>
      uri.isEmpty ? head : '$head\n$uri';

  static Future<void> _share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}
