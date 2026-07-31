import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _activePluginIdKey = 'active_metadata_plugin_id';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  String? getActivePluginId() {
    return _prefs.getString(_activePluginIdKey);
  }

  Future<bool> setActivePluginId(String pluginId) {
    return _prefs.setString(_activePluginIdKey, pluginId);
  }

  Future<bool> removeActivePluginId() {
    return _prefs.remove(_activePluginIdKey);
  }
}
