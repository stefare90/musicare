import 'package:gyawun_metadata_sdk/metadata/interfaces/istorage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService implements IStorageService {
  final SharedPreferences prefs;
  final String storageKeyPrefix = 'plugin_storage_';

  StorageService(this.prefs);

  @override
  Future<void> clear() async {
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(storageKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  @override
  Future<void> delete(String key) async {
    await prefs.remove(storageKeyPrefix + key);
  }

  @override
  Future<String?> get(String key) async {
    return prefs.getString(storageKeyPrefix + key);
  }

  @override
  Future<void> set(String key, String value) async {
    await prefs.setString(storageKeyPrefix + key, value);
  }
}
