import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

void main() {
  group('PluginManifest Model Unit Tests', () {
    test(
      'fromJson correctly parses complete JSON map and detects PluginType',
      () {
        final json = {
          'id': 'org.gyawun.musicbrainz',
          'packageId': 'gyawun_metadata_plugin',
          'type': 'metadata',
          'name': 'MusicBrainz & ListenBrainz',
          'version': '1.0.0',
          'pluginSdkVersion': '1.0.0',
          'author': 'MusicAre Team',
          'description': 'Test description',
          'repository': 'https://github.com/stefare90/gyawun_metadata_plugin',
        };

        final manifest = PluginManifest.fromJson(json);

        expect(manifest.id, equals('org.gyawun.musicbrainz'));
        expect(manifest.packageId, equals('gyawun_metadata_plugin'));
        expect(manifest.type, equals('metadata'));
        expect(manifest.pluginType, equals(PluginType.metadata));
        expect(manifest.name, equals('MusicBrainz & ListenBrainz'));
        expect(manifest.version, equals('1.0.0'));
        expect(manifest.pluginSdkVersion, equals('1.0.0'));
        expect(manifest.author, equals('MusicAre Team'));
        expect(manifest.description, equals('Test description'));
        expect(
          manifest.repository,
          equals('https://github.com/stefare90/gyawun_metadata_plugin'),
        );
      },
    );

    test('fromJson handles null repository field and audioSource type', () {
      final json = {
        'id': 'org.musicare.audiosource.youtube',
        'packageId': 'musicare_audiosource_youtube_plugin',
        'type': 'audioSource',
        'name': 'YouTube Audio Source',
        'version': '1.0.0',
        'pluginSdkVersion': '1.0.0',
        'author': 'MusicAre Team',
        'description': 'Test description',
        'repository': null,
      };

      final manifest = PluginManifest.fromJson(json);

      expect(manifest.repository, isNull);
      expect(manifest.pluginType, equals(PluginType.audioSource));
    });
  });
}
