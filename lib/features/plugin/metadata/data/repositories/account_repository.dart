import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class AccountRepository {
  AccountRepository(this._engine, this._preferences);

  final MetadataPluginEngine _engine;
  final PreferencesService _preferences;

  bool get hasMetadata => _engine.hasMetadata;

  Future<bool> isAuthenticated() => _engine.metadata.auth.isAuthenticated();

  Future<void> authenticate() => _engine.metadata.auth.authenticate();

  /// Synchronous so an offline boot can show who is signed in without
  /// waiting for the provider.
  String? get cachedUserId => _preferences.getMetadataUserId();

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
