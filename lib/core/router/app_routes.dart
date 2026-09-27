abstract class AppRoutes {
  // Absolute, navigable locations.
  static const String home = '/';
  static const String pluginUpdate = '/plugin-update';
  static const String welcome = '/welcome';
  static const String search = '/search';
  static const String library = '/library';

  // Relative child segments; the absolute locations are derived from them.
  static const String playlistSegment = 'playlist';
  static const String albumSegment = 'album';
  static const String artistSegment = 'artist';

  static const String playlist = '/$playlistSegment';
  static const String album = '/$albumSegment';
  static const String artist = '/$artistSegment';

  static const String settings = '/settings';
  static const String pluginTypeParam = 'type';
  static const String settingsPluginSegment = 'plugin/:$pluginTypeParam';
  static const String settingsPlugin = '$settings/plugin';
}
