abstract class AppRoutes {
  static const String home = '/';
  static const String pluginUpdate = '/plugin-update';
  static const String pluginUpdateTypeParam = 'type';
  static const String pluginUpdateSegment =
      '$pluginUpdate/:$pluginUpdateTypeParam';
  static const String welcome = '/welcome';
  static const String search = '/search';
  static const String library = '/library';

  static const String playlistSegment = 'playlist';
  static const String albumSegment = 'album';
  static const String artistSegment = 'artist';

  static const String playlist = '/$playlistSegment';
  static const String album = '/$albumSegment';
  static const String artist = '/$artistSegment';

  static const String likedSegment = 'liked';
  static const String downloadsSegment = 'downloads';
  static const String likedTracks = '$library/$likedSegment';
  static const String downloads = '$library/$downloadsSegment';

  static const String settings = '/settings';
  static const String pluginTypeParam = 'type';
  static const String settingsPluginSegment = 'plugin/:$pluginTypeParam';
  static const String settingsPlugin = '$settings/plugin';
  static const String settingsAboutSegment = 'about';
  static const String settingsAbout = '$settings/$settingsAboutSegment';
}
