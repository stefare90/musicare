import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class MockAudioSourcePluginCubit extends Mock
    implements AudioSourcePluginCubit {}

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

AudioSourcePluginLoadedState testAudioSourceLoadedState({
  String name = 'Test Audio',
}) => AudioSourcePluginLoadedState(
  manifest: testAudioSourceManifest(name: name),
  port: 1234,
);

AudioSourcePluginCubit buildMockAudioSourcePluginCubit({
  AudioSourcePluginState? state,
}) {
  final cubit = MockAudioSourcePluginCubit();
  when(() => cubit.state).thenReturn(state ?? testAudioSourceLoadedState());
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  return cubit;
}
