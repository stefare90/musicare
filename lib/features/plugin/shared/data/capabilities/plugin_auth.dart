import 'package:musicare_auth_host_sdk/musicare_auth_host_sdk.dart'
    show Account;

import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';

abstract interface class PluginAuth {
  bool get isAvailable;
  PluginAuthState get authState;
  Stream<PluginAuthState> get authChanges;

  Future<bool> isAuthenticated();
  Future<void> authenticate();
  Future<void> logout();
  Future<void> refresh();

  Account? get cachedAccount;
}
