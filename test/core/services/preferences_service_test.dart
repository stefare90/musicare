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

    test('active plugin version dirs use one generic key per type', () async {
      expect(service.activePluginVersionDir(PluginType.metadata), isNull);

      await service.setActivePluginVersionDir(PluginType.metadata, '4.0.1');
      await service.setActivePluginVersionDir(PluginType.audioSource, '1.0.0-2');

      expect(service.activePluginVersionDir(PluginType.metadata), '4.0.1');
      expect(service.activePluginVersionDir(PluginType.audioSource), '1.0.0-2');
      expect(prefs.getString('metadata_active_plugin_version_dir'), '4.0.1');

      await service.clearActivePluginVersionDir(PluginType.metadata);
      expect(service.activePluginVersionDir(PluginType.metadata), isNull);
      expect(service.activePluginVersionDir(PluginType.audioSource), '1.0.0-2');
    });

    test('plugin accounts are scoped per plugin and keep id and name', () async {
      await service.setPluginAccount('first.plugin', id: 'listener', name: 'Listener');

      expect(service.pluginAccount('first.plugin'), (id: 'listener', name: 'Listener'));
      expect(
        prefs.getString('plugin_account_first.plugin'),
        '{"id":"listener","name":"Listener"}',
      );
      expect(service.pluginAccount('second.plugin'), isNull);
    });

    test('a plugin account without a name round-trips id-only', () async {
      await service.setPluginAccount('first.plugin', id: 'listener');

      expect(service.pluginAccount('first.plugin'), (id: 'listener', name: null));
    });

    test('a malformed cached account is ignored', () async {
      prefs.setString('plugin_account_old.plugin', 'plugin_account_id_old');

      expect(service.pluginAccount('old.plugin'), isNull);
    });

    test('removePluginAccount clears the cached account', () async {
      await service.setPluginAccount('first.plugin', id: 'listener', name: 'Listener');

      await service.removePluginAccount('first.plugin');

      expect(service.pluginAccount('first.plugin'), isNull);
    });

    test('removePluginScopedKeys clears keys of a non-active plugin', () async {
      await service.setPluginAccount('old.plugin', id: 'listener');
      await service.setPluginAccount('new.plugin', id: 'other');
      await service.setActivePluginId(PluginType.metadata, 'new.plugin');

      await service.removePluginScopedKeys('old.plugin');

      expect(service.pluginAccount('old.plugin'), isNull);
      expect(service.pluginAccount('new.plugin'), (id: 'other', name: null));
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
