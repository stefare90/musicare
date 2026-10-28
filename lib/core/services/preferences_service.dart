import 'package:flutter/material.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _activePluginIdSuffix = '_active_plugin_id';
  static const String _pluginAccountIdPrefix = 'plugin_account_id_';
  static const String _legacyMetadataUserIdPrefix = 'metadata_user_id_';
  static const String _themeModeKey = 'theme_mode';
  static const String _accentKey = 'accent_color';
  static const String _amoledBlackKey = 'amoled_black';
  static const String _languageCodeKey = 'language_code';
  static const String _infiniteMusicKey = 'infinite_music';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  String _activePluginKey(PluginType type) =>
      '${type.name.toLowerCase()}$_activePluginIdSuffix';

  String? activePluginId(PluginType type) =>
      _prefs.getString(_activePluginKey(type));

  Future<bool> setActivePluginId(PluginType type, String pluginId) =>
      _prefs.setString(_activePluginKey(type), pluginId);

  Future<bool> clearActivePluginId(PluginType type) =>
      _prefs.remove(_activePluginKey(type));

  String? pluginAccountId(String pluginId) {
    return _prefs.getString('$_pluginAccountIdPrefix$pluginId') ??
        _prefs.getString('$_legacyMetadataUserIdPrefix$pluginId');
  }

  Future<bool> setPluginAccountId(String pluginId, String accountId) =>
      _prefs.setString('$_pluginAccountIdPrefix$pluginId', accountId);

  Future<bool> removePluginAccountId(String pluginId) async {
    final removed = await _prefs.remove('$_pluginAccountIdPrefix$pluginId');
    await _prefs.remove('$_legacyMetadataUserIdPrefix$pluginId');
    return removed;
  }

  Future<void> migratePluginAccountId(String pluginId) async {
    final legacy = _prefs.getString('$_legacyMetadataUserIdPrefix$pluginId');
    if (legacy == null) return;
    final key = '$_pluginAccountIdPrefix$pluginId';
    if (!_prefs.containsKey(key)) {
      await _prefs.setString(key, legacy);
    }
    await _prefs.remove('$_legacyMetadataUserIdPrefix$pluginId');
  }

  Future<void> removePluginScopedKeys(String pluginId) async {
    await removePluginAccountId(pluginId);
  }

  ThemeMode? getThemeMode() =>
      _enumByName(ThemeMode.values, _prefs.getString(_themeModeKey));
  Future<bool> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeModeKey, mode.name);

  AppAccent? getAccent() =>
      _enumByName(AppAccent.values, _prefs.getString(_accentKey));
  Future<bool> setAccent(AppAccent accent) =>
      _prefs.setString(_accentKey, accent.name);

  bool? getAmoledBlack() => _prefs.getBool(_amoledBlackKey);
  Future<bool> setAmoledBlack(bool value) =>
      _prefs.setBool(_amoledBlackKey, value);

  String? getLanguageCode() => _prefs.getString(_languageCodeKey);
  Future<bool> setLanguageCode(String code) =>
      _prefs.setString(_languageCodeKey, code);

  bool? getInfiniteMusic() => _prefs.getBool(_infiniteMusicKey);
  Future<bool> setInfiniteMusic(bool value) =>
      _prefs.setBool(_infiniteMusicKey, value);
}

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
