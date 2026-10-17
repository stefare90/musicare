import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/theme/app_accent.dart';
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

    test('metadata user id is cached per active plugin', () async {
      await service.setMetadataUserId('listener');
      expect(service.getMetadataUserId(), 'listener');
      expect(
        prefs.getString('metadata_user_id_org.gyawun.musicbrainz'),
        'listener',
      );

      await service.setActivePluginId('org.gyawun.spotify');
      expect(service.getMetadataUserId(), isNull);

      await service.setMetadataUserId('other');
      await service.setActivePluginId('org.gyawun.musicbrainz');
      expect(service.getMetadataUserId(), 'listener');
    });

    test('removeMetadataUserId clears the cached identity', () async {
      await service.setMetadataUserId('listener');

      await service.removeMetadataUserId();

      expect(service.getMetadataUserId(), isNull);
    });

    test('theme mode defaults to null and round-trips', () async {
      expect(service.getThemeMode(), isNull);

      await service.setThemeMode(ThemeMode.light);

      expect(service.getThemeMode(), ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('accent defaults to null and round-trips', () async {
      expect(service.getAccent(), isNull);

      await service.setAccent(AppAccent.blue);

      expect(service.getAccent(), AppAccent.blue);
      expect(prefs.getString('accent_color'), 'blue');
    });

    test('amoled black is tri-state and round-trips', () async {
      expect(service.getAmoledBlack(), isNull);

      await service.setAmoledBlack(false);

      expect(service.getAmoledBlack(), isFalse);
      expect(prefs.getBool('amoled_black'), isFalse);
    });

    test('language code defaults to null and round-trips', () async {
      expect(service.getLanguageCode(), isNull);

      await service.setLanguageCode('en');

      expect(service.getLanguageCode(), 'en');
      expect(prefs.getString('language_code'), 'en');
    });
  });
}
