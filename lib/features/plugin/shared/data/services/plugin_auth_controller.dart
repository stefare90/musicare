import 'dart:async';

import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_auth.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:musicare_auth_host_sdk/musicare_auth_host_sdk.dart';

class PluginAuthController implements PluginAuth {
  PluginAuthController({
    required this.available,
    required this.activePluginId,
    required this.flow,
    required this.preferences,
    required this.isUnsupported,
  });

  final bool Function() available;
  final String? Function() activePluginId;
  final IAuth flow;
  final PreferencesService preferences;
  final bool Function(Object error) isUnsupported;
  final StreamController<PluginAuthState> _changes =
      StreamController<PluginAuthState>.broadcast();

  PluginAuthState _state = const PluginAuthState.unavailable();

  @override
  bool get isAvailable => available();

  @override
  PluginAuthState get authState => _state;

  @override
  Stream<PluginAuthState> get authChanges => _changes.stream;

  @override
  Account? get cachedAccount {
    final pluginId = activePluginId();
    if (pluginId == null) return null;
    final cached = preferences.pluginAccount(pluginId);
    if (cached == null) return null;
    return Account(id: cached.id, displayName: cached.name);
  }

  @override
  Future<bool> isAuthenticated() async {
    if (!available()) return false;
    try {
      return (await flow.status()).authenticated;
    } catch (error) {
      if (isUnsupported(error)) return false;
      rethrow;
    }
  }

  @override
  Future<void> authenticate() async {
    if (!available()) throw PluginNotLoadedException();
    final pluginId = activePluginId();
    _emit(const PluginAuthState.loading());
    try {
      final status = await flow.authenticate();
      if (activePluginId() != pluginId) return;
      if (!status.authenticated) {
        _emit(const PluginAuthState.signedOut());
        return;
      }
      await _applySignedIn(pluginId, status.account);
    } catch (error) {
      _emit(
        isUnsupported(error)
            ? const PluginAuthState.unavailable()
            : PluginAuthState.failure(error),
      );
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    if (!available()) {
      _emit(const PluginAuthState.signedOut());
      return;
    }
    final pluginId = activePluginId();
    try {
      await flow.logout();
    } finally {
      if (pluginId != null && activePluginId() == pluginId) {
        await preferences.removePluginAccount(pluginId);
        _emit(const PluginAuthState.signedOut());
      }
    }
  }

  @override
  Future<void> refresh() async {
    if (!available()) {
      _emit(const PluginAuthState.unavailable());
      return;
    }
    final pluginId = activePluginId();
    try {
      final status = await flow.status();
      if (activePluginId() != pluginId) return;
      if (!status.authenticated) {
        if (pluginId != null) {
          await preferences.removePluginAccount(pluginId);
        }
        if (activePluginId() != pluginId) return;
        _emit(const PluginAuthState.signedOut());
        return;
      }
      await _applySignedIn(pluginId, status.account);
    } catch (error) {
      _emit(
        isUnsupported(error)
            ? const PluginAuthState.unavailable()
            : PluginAuthState.failure(error),
      );
    }
  }

  /// The contract allows an authenticated plugin with no account: the cached
  /// one keeps the identity across restarts, and `null` is a valid state.
  Future<void> _applySignedIn(String? pluginId, Account? reported) async {
    final account = reported ?? cachedAccount;
    if (pluginId != null && account != null) {
      await preferences.setPluginAccount(
        pluginId,
        id: account.id,
        name: account.displayName,
      );
    }
    if (activePluginId() != pluginId) return;
    _emit(PluginAuthState.signedIn(account));
  }

  void _emit(PluginAuthState state) {
    _state = state;
    if (!_changes.isClosed) _changes.add(state);
  }
}
