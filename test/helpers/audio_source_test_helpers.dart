import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

PluginManifest testAudioSourceManifest({String name = 'Test Audio'}) =>
    PluginManifest(
      id: 'test.audio',
      packageId: 'test_audio',
      type: 'audio_source',
      name: name,
      version: '1.0.0',
      pluginSdkVersion: '4.1.0',
      author: 'Test',
      description: 'Test audio plugin',
    );
