enum PluginAuthStatus { unavailable, signedOut, signedIn, loading, error }

class PluginAuthState {
  final PluginAuthStatus status;
  final String? accountId;
  final Object? error;

  const PluginAuthState.unavailable()
    : status = PluginAuthStatus.unavailable,
      accountId = null,
      error = null;

  const PluginAuthState.signedOut()
    : status = PluginAuthStatus.signedOut,
      accountId = null,
      error = null;

  const PluginAuthState.signedIn(String this.accountId)
    : status = PluginAuthStatus.signedIn,
      error = null;

  const PluginAuthState.loading()
    : status = PluginAuthStatus.loading,
      accountId = null,
      error = null;

  const PluginAuthState.failure(Object this.error)
    : status = PluginAuthStatus.error,
      accountId = null;

  bool get isAuthenticated => status == PluginAuthStatus.signedIn;
}
