import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/metadata/data/services/sdk_services/plugin_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService (for SDK) Unit Tests', () {
    late StorageService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'plugin_storage_token': 'test_token',
        'app_theme_mode': 'dark',
      });
      prefs = await SharedPreferences.getInstance();
      service = StorageService(prefs);
    });

    test('get should return unboxed value if prefixed key exists', () async {
      final token = await service.get('token');
      expect(token, equals('test_token'));
    });

    test(
      'clear should remove all plugin keys but keep host keys intact',
      () async {
        await service.set('username', 'test_user');
        await service.clear();

        expect(await service.get('token'), isNull);
        expect(prefs.getString('plugin_storage_username'), isNull);
        expect(prefs.getString('app_theme_mode'), equals('dark'));
      },
    );
  });
}
