import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/data/services/plugin_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Required to mock platform channels for SharedPreferences in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Unit Tests', () {
    late StorageService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'plugin_storage_token': 'test_token',
        'app_theme_mode': 'dark', // Simulating a host app native preference.
      });
      prefs = await SharedPreferences.getInstance();
      service = StorageService(prefs);
    });

    test('get should return unboxed value if prefixed key exists', () async {
      final token = await service.get('token');
      expect(token, equals('test_token'));
    });

    test('get should return null if key is not prefixed in storage', () async {
      final theme = await service.get('app_theme_mode');
      expect(theme, isNull);
    });

    test('set should save value with namespace prefix', () async {
      await service.set('username', 'test_user');

      expect(prefs.getString('plugin_storage_username'), equals('test_user'));
    });

    test('delete should remove only the specified prefixed key', () async {
      await service.delete('token');

      expect(prefs.getString('plugin_storage_token'), isNull);
      expect(prefs.getString('app_theme_mode'), equals('dark'));
    });

    test(
      'clear should remove all plugin keys but keep host keys intact',
      () async {
        await service.set('username', 'test_user');

        await service.clear();

        expect(await service.get('token'), isNull);
        expect(prefs.getString('plugin_storage_username'), isNull);
        expect(
          prefs.getString('app_theme_mode'),
          equals('dark'),
        ); // Verifying isolation.
      },
    );
  });
}
