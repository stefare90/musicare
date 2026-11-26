import 'package:musicare_auth_host_sdk/musicare_auth_host_sdk.dart';

enum PluginAuthStatus { unavailable, signedOut, signedIn, loading, error }

class PluginAuthState {
  final PluginAuthStatus status;

  final Account? account;

  final Object? error;

  const PluginAuthState.unavailable()
    : status = PluginAuthStatus.unavailable,
      account = null,
      error = null;

  const PluginAuthState.signedOut()
    : status = PluginAuthStatus.signedOut,
      account = null,
      error = null;

  const PluginAuthState.signedIn([this.account])
    : status = PluginAuthStatus.signedIn,
      error = null;

  const PluginAuthState.loading()
    : status = PluginAuthStatus.loading,
      account = null,
      error = null;

  const PluginAuthState.failure(Object this.error)
    : status = PluginAuthStatus.error,
      account = null;

  bool get isAuthenticated => status == PluginAuthStatus.signedIn;

  String? get accountId => account?.id;

  String? get displayName => account?.displayName ?? account?.id;
}
