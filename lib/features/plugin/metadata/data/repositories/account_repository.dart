import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

/// Data access for the account: authentication and the provider identity.
///
/// Limited scope on purpose: it exposes only what `UserCubit` needs (`IAuth`
/// plus the user id from `IUser.me()`), never the whole engine.
class AccountRepository {
  AccountRepository(this._engine, this._preferences);

  final MetadataPluginEngine _engine;
  final PreferencesService _preferences;

  bool get hasMetadata => _engine.hasMetadata;

  Future<bool> isAuthenticated() => _engine.metadata.auth.isAuthenticated();

  Future<void> authenticate() => _engine.metadata.auth.authenticate();

  /// The identity from the last successful resolution, read from local storage.
  ///
  /// Synchronous on purpose: an offline boot can show who is signed in without
  /// waiting for the provider (which would otherwise leave the id null and break
  /// every ownership check).
  String? get cachedUserId => _preferences.getMetadataUserId();

  /// Resolves the provider identity and remembers it for offline boots.
  ///
  /// Throws when the provider cannot be reached; the caller falls back to
  /// [cachedUserId].
  Future<String?> resolveUserId() async {
    final me = await _engine.metadata.user.me();
    final userId = me['user_id'];
    if (userId is! String || userId.isEmpty) return null;
    await _preferences.setMetadataUserId(userId);
    return userId;
  }

  Future<void> logout() async {
    try {
      await _engine.metadata.auth.logout();
    } finally {
      await _preferences.removeMetadataUserId();
    }
  }
}
