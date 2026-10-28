import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService Unit Tests', () {
    late SharedPreferences prefs;
    late PreferencesService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = PreferencesService(prefs);
    });

    test('active plugin ids use one generic key per type', () async {
      expect(service.activePluginId(PluginType.metadata), isNull);
      expect(service.activePluginId(PluginType.audioSource), isNull);

      await service.setActivePluginId(
        PluginType.metadata,
        'org.musicare.metadata.musicbrainz',
      );
      await service.setActivePluginId(
        PluginType.audioSource,
        'org.musicare.audiosource.youtube',
      );

      expect(
        service.activePluginId(PluginType.metadata),
        'org.musicare.metadata.musicbrainz',
      );
      expect(
        service.activePluginId(PluginType.audioSource),
        'org.musicare.audiosource.youtube',
      );
      expect(
        prefs.getString('metadata_active_plugin_id'),
        'org.musicare.metadata.musicbrainz',
      );
      expect(
        prefs.getString('audiosource_active_plugin_id'),
        'org.musicare.audiosource.youtube',
      );
    });

    test('clearActivePluginId removes only the requested type', () async {
      await service.setActivePluginId(PluginType.metadata, 'metadata.plugin');
      await service.setActivePluginId(PluginType.audioSource, 'audio.plugin');

      await service.clearActivePluginId(PluginType.metadata);

      expect(service.activePluginId(PluginType.metadata), isNull);
      expect(service.activePluginId(PluginType.audioSource), 'audio.plugin');
    });

    test('plugin account ids are scoped per plugin', () async {
      await service.setPluginAccountId('first.plugin', 'listener');

      expect(service.pluginAccountId('first.plugin'), 'listener');
      expect(prefs.getString('plugin_account_id_first.plugin'), 'listener');
      expect(service.pluginAccountId('second.plugin'), isNull);
    });

    test('removePluginAccountId clears both generic and legacy keys', () async {
      await service.setPluginAccountId('first.plugin', 'listener');
      prefs.setString('metadata_user_id_first.plugin', 'listener');

      await service.removePluginAccountId('first.plugin');

      expect(service.pluginAccountId('first.plugin'), isNull);
      expect(prefs.getString('metadata_user_id_first.plugin'), isNull);
    });

    test('legacy metadata account id is read and migrated', () async {
      prefs.setString('metadata_user_id_old.plugin', 'listener');

      expect(service.pluginAccountId('old.plugin'), 'listener');

      await service.migratePluginAccountId('old.plugin');

      expect(prefs.getString('metadata_user_id_old.plugin'), isNull);
      expect(prefs.getString('plugin_account_id_old.plugin'), 'listener');
    });

    test('removePluginScopedKeys clears keys of a non-active plugin', () async {
      prefs.setString('metadata_user_id_old.plugin', 'listener');
      prefs.setString('metadata_user_id_new.plugin', 'other');
      await service.setActivePluginId(PluginType.metadata, 'new.plugin');

      await service.removePluginScopedKeys('old.plugin');

      expect(prefs.getString('metadata_user_id_old.plugin'), isNull);
      expect(prefs.getString('metadata_user_id_new.plugin'), 'other');
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
