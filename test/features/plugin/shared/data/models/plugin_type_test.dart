import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

void main() {
  group('PluginType Unit Tests', () {
    test('fromString parses metadata types case-insensitively', () {
      expect(PluginType.fromString('metadata'), equals(PluginType.metadata));
      expect(PluginType.fromString('METADATA'), equals(PluginType.metadata));
      expect(PluginType.fromString('MetaData'), equals(PluginType.metadata));
    });

    test('fromString parses audioSource and audio_source formats', () {
      expect(
        PluginType.fromString('audiosource'),
        equals(PluginType.audioSource),
      );
      expect(
        PluginType.fromString('audio_source'),
        equals(PluginType.audioSource),
      );
      expect(
        PluginType.fromString('AudioSource'),
        equals(PluginType.audioSource),
      );
      expect(
        PluginType.fromString('AUDIO_SOURCE'),
        equals(PluginType.audioSource),
      );
    });

    test('fromString returns null for unknown or invalid types', () {
      expect(PluginType.fromString(''), isNull);
      expect(PluginType.fromString('lyrics'), isNull);
      expect(PluginType.fromString('custom_plugin'), isNull);
    });
  });
}
