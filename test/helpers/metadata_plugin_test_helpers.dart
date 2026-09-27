import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class MockMetadataPluginCubit extends Mock implements MetadataPluginCubit {}

PluginManifest testPluginManifest({String name = 'Test Provider'}) =>
    PluginManifest(
      id: 'test.plugin',
      packageId: 'test_plugin',
      type: 'metadata',
      name: name,
      version: '1.0.0',
      pluginSdkVersion: '4.1.0',
      author: 'Test',
      description: 'Test plugin',
    );

MetadataPluginLoadedState testLoadedState({
  bool isAuthenticated = false,
  String? userName,
  String pluginName = 'Test Provider',
}) => MetadataPluginLoadedState(
  manifest: testPluginManifest(name: pluginName),
  isAuthenticated: isAuthenticated,
  userName: userName,
);

MetadataPluginCubit buildMockMetadataPluginCubit({
  MetadataPluginState? state,
  Stream<MetadataPluginState>? stream,
  Future<AuthResult> Function()? onAuthenticate,
  Future<void> Function()? onLogout,
}) {
  final cubit = MockMetadataPluginCubit();
  when(() => cubit.state).thenReturn(state ?? testLoadedState());
  when(() => cubit.stream).thenAnswer((_) => stream ?? const Stream.empty());
  when(() => cubit.authenticate()).thenAnswer(
    (_) async => onAuthenticate == null
        ? AuthResult.authenticated
        : await onAuthenticate(),
  );
  when(() => cubit.logout()).thenAnswer((_) async {
    await onLogout?.call();
  });
  return cubit;
}
