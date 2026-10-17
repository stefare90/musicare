import 'package:flutter/material.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _activeMetadataPluginIdKey = 'active_metadata_plugin_id';
  static const String _activeAudioSourcePluginIdKey =
      'active_audio_source_plugin_id';
  static const String _metadataUserIdPrefix = 'metadata_user_id_';
  static const String _themeModeKey = 'theme_mode';
  static const String _accentKey = 'accent_color';
  static const String _amoledBlackKey = 'amoled_black';
  static const String _languageCodeKey = 'language_code';

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
}

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
