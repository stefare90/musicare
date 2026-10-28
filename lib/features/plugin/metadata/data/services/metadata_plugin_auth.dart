import 'dart:async';

import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_auth.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';

class MetadataPluginAuth implements PluginAuth {
  MetadataPluginAuth(this._engine, this._preferences);

  final MetadataPluginEngine _engine;
  final PreferencesService _preferences;
  final StreamController<PluginAuthState> _changes =
      StreamController<PluginAuthState>.broadcast();
  PluginAuthState _state = const PluginAuthState.unavailable();

  @override
  bool get isAvailable => _engine.hasMetadata;

  @override
  PluginAuthState get authState => _state;

  @override
  Stream<PluginAuthState> get authChanges => _changes.stream;

  @override
  Future<bool> isAuthenticated() async {
    if (!isAvailable) return false;
    return _engine.metadata.auth.isAuthenticated();
  }

  @override
  Future<void> authenticate() async {
    if (!isAvailable) throw PluginNotLoadedException();
    _emit(const PluginAuthState.loading());
    try {
      await _engine.metadata.auth.authenticate();
      await refresh();
    } catch (error) {
      _emit(PluginAuthState.failure(error));
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    if (!isAvailable) {
      _emit(const PluginAuthState.signedOut());
      return;
    }
    final pluginId = _engine.metadataManifest?.id;
    try {
      await _engine.metadata.auth.logout();
    } finally {
      if (pluginId != null && _engine.metadataManifest?.id == pluginId) {
        await _preferences.removePluginAccountId(pluginId);
      }
      _emit(const PluginAuthState.signedOut());
    }
  }

  @override
  Future<void> refresh() async {
    if (!isAvailable) {
      _emit(const PluginAuthState.unavailable());
      return;
    }
    final pluginId = _engine.metadataManifest?.id;
    try {
      if (pluginId != null) {
        await _preferences.migratePluginAccountId(pluginId);
      }
      final isAuthenticated = await _engine.metadata.auth.isAuthenticated();
      if (_engine.metadataManifest?.id != pluginId) return;
      if (!isAuthenticated) {
        _emit(const PluginAuthState.signedOut());
        return;
      }
      final accountId = pluginId == null
          ? null
          : _preferences.pluginAccountId(pluginId);
      _emit(
        accountId == null
            ? const PluginAuthState.signedIn('')
            : PluginAuthState.signedIn(accountId),
      );
    } catch (error) {
      _emit(PluginAuthState.failure(error));
    }
  }

  @override
  String? get cachedAccountId {
    final pluginId = _engine.metadataManifest?.id;
    return pluginId == null ? null : _preferences.pluginAccountId(pluginId);
  }

  @override
  Future<String?> resolveAccountId() async {
    if (!isAvailable) return null;
    final pluginId = _engine.metadataManifest?.id;
    final me = await _engine.metadata.user.me();
    if (pluginId == null || _engine.metadataManifest?.id != pluginId) {
      return null;
    }
    final accountId = me['user_id'];
    if (accountId is! String || accountId.isEmpty) return null;
    await _preferences.setPluginAccountId(pluginId, accountId);
    _emit(PluginAuthState.signedIn(accountId));
    return accountId;
  }

  void _emit(PluginAuthState state) {
    _state = state;
    if (!_changes.isClosed) _changes.add(state);
  }
}
