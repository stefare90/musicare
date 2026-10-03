import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

/// Data access for the account: authentication and the provider identity.
///
/// Limited scope on purpose: it exposes only what `AccountCubit` needs (`IAuth`
/// plus the user id from `IUser.me()`), never the whole engine.
class AccountRepository {
  AccountRepository(this._engine);

  final MetadataPluginEngine _engine;

  bool get hasMetadata => _engine.hasMetadata;

  Future<bool> isAuthenticated() => _engine.metadata.auth.isAuthenticated();

  Future<void> authenticate() => _engine.metadata.auth.authenticate();

  Future<void> logout() => _engine.metadata.auth.logout();

  /// The provider's user id (its user name), or null when unavailable.
  Future<String?> userId() async {
    final me = await _engine.metadata.user.me();
    final userId = me['user_id'];
    return userId is String && userId.isNotEmpty ? userId : null;
  }
}
