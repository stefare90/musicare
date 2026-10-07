import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _activeMetadataPluginIdKey = 'active_metadata_plugin_id';
  static const String _activeAudioSourcePluginIdKey =
      'active_audio_source_plugin_id';
  static const String _metadataUserIdPrefix = 'metadata_user_id_';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  String? getActivePluginId() => _prefs.getString(_activeMetadataPluginIdKey);
  Future<bool> setActivePluginId(String pluginId) =>
      _prefs.setString(_activeMetadataPluginIdKey, pluginId);
  Future<bool> removeActivePluginId() =>
      _prefs.remove(_activeMetadataPluginIdKey);

  String? getMetadataUserId() {
    final pluginId = getActivePluginId();
    if (pluginId == null) return null;
    return _prefs.getString('$_metadataUserIdPrefix$pluginId');
  }

  Future<bool> setMetadataUserId(String userId) {
    final pluginId = getActivePluginId();
    if (pluginId == null) return Future.value(false);
    return _prefs.setString('$_metadataUserIdPrefix$pluginId', userId);
  }

  Future<bool> removeMetadataUserId() {
    final pluginId = getActivePluginId();
    if (pluginId == null) return Future.value(false);
    return _prefs.remove('$_metadataUserIdPrefix$pluginId');
  }

  String? getActiveAudioSourcePluginId() =>
      _prefs.getString(_activeAudioSourcePluginIdKey);
  Future<bool> setActiveAudioSourcePluginId(String pluginId) =>
      _prefs.setString(_activeAudioSourcePluginIdKey, pluginId);
  Future<bool> removeActiveAudioSourcePluginId() =>
      _prefs.remove(_activeAudioSourcePluginIdKey);
}
