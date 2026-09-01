import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _activeMetadataPluginIdKey = 'active_metadata_plugin_id';
  static const String _activeAudioSourcePluginIdKey =
      'active_audio_source_plugin_id';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Metadata plugin
  String? getActivePluginId() => _prefs.getString(_activeMetadataPluginIdKey);
  Future<bool> setActivePluginId(String pluginId) =>
      _prefs.setString(_activeMetadataPluginIdKey, pluginId);
  Future<bool> removeActivePluginId() =>
      _prefs.remove(_activeMetadataPluginIdKey);

  // Audio source plugin
  String? getActiveAudioSourcePluginId() =>
      _prefs.getString(_activeAudioSourcePluginIdKey);
  Future<bool> setActiveAudioSourcePluginId(String pluginId) =>
      _prefs.setString(_activeAudioSourcePluginIdKey, pluginId);
  Future<bool> removeActiveAudioSourcePluginId() =>
      _prefs.remove(_activeAudioSourcePluginIdKey);
}
