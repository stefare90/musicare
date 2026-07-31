import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService Unit Tests', () {
    late PreferencesService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'active_metadata_plugin_id': 'org.gyawun.musicbrainz',
      });
      prefs = await SharedPreferences.getInstance();
      service = PreferencesService(prefs);
    });

    test('getActivePluginId returns saved plugin id', () {
      final pluginId = service.getActivePluginId();
      expect(pluginId, equals('org.gyawun.musicbrainz'));
    });

    test('setActivePluginId persists new plugin id', () async {
      final success = await service.setActivePluginId('org.gyawun.spotify');

      expect(success, isTrue);
      expect(service.getActivePluginId(), equals('org.gyawun.spotify'));
      expect(
        prefs.getString('active_metadata_plugin_id'),
        equals('org.gyawun.spotify'),
      );
    });

    test('removeActivePluginId removes plugin id key', () async {
      final success = await service.removeActivePluginId();

      expect(success, isTrue);
      expect(service.getActivePluginId(), isNull);
      expect(prefs.getString('active_metadata_plugin_id'), isNull);
    });
  });
}
