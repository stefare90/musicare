import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef PluginAccount = ({String id, String? name});

class PreferencesService {
  static const String _activePluginIdSuffix = '_active_plugin_id';
  static const String _activePluginVersionDirSuffix =
      '_active_plugin_version_dir';
  static const String _pluginAccountPrefix = 'plugin_account_';
  static const String _themeModeKey = 'theme_mode';
  static const String _accentKey = 'accent_color';
  static const String _amoledBlackKey = 'amoled_black';
  static const String _languageCodeKey = 'language_code';
  static const String _infiniteMusicKey = 'infinite_music';
  static const String _runtimeSessionKey = 'runtime_session';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  String _activePluginKey(PluginType type) =>
      '${type.name.toLowerCase()}$_activePluginIdSuffix';

  String _activePluginVersionDirKey(PluginType type) =>
      '${type.name.toLowerCase()}$_activePluginVersionDirSuffix';

  String? activePluginId(PluginType type) =>
      _prefs.getString(_activePluginKey(type));

  Future<bool> setActivePluginId(PluginType type, String pluginId) =>
      _prefs.setString(_activePluginKey(type), pluginId);

  Future<bool> clearActivePluginId(PluginType type) =>
      _prefs.remove(_activePluginKey(type));

  String? activePluginVersionDir(PluginType type) =>
      _prefs.getString(_activePluginVersionDirKey(type));

  Future<bool> setActivePluginVersionDir(PluginType type, String versionDir) =>
      _prefs.setString(_activePluginVersionDirKey(type), versionDir);

  Future<bool> clearActivePluginVersionDir(PluginType type) =>
      _prefs.remove(_activePluginVersionDirKey(type));

  PluginAccount? pluginAccount(String pluginId) {
    final raw = _prefs.getString('$_pluginAccountPrefix$pluginId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final id = decoded['id'];
      if (id is! String || id.isEmpty) return null;
      final name = decoded['name'];
      return (id: id, name: name is String && name.isNotEmpty ? name : null);
    } on FormatException {
      return null;
    }
  }

  Future<bool> setPluginAccount(
    String pluginId, {
    required String id,
    String? name,
  }) => _prefs.setString(
    '$_pluginAccountPrefix$pluginId',
    jsonEncode({'id': id, 'name': ?name}),
  );

  Future<bool> removePluginAccount(String pluginId) =>
      _prefs.remove('$_pluginAccountPrefix$pluginId');

  Future<void> removePluginScopedKeys(String pluginId) async {
    await removePluginAccount(pluginId);
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

  String? getRuntimeSession() => _prefs.getString(_runtimeSessionKey);
  Future<bool> setRuntimeSession(String value) =>
      _prefs.setString(_runtimeSessionKey, value);
}

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
