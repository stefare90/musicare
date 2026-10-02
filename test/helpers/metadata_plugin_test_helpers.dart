import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class MockMetadataPluginCubit extends Mock implements MetadataPluginCubit {}

class MockAccountCubit extends Mock implements AccountCubit {}

/// Controllable account cubit: tests can push [AccountState]s to simulate
/// sign-in/sign-out without an engine.
class TestAccountCubit extends Cubit<AccountState> {
  TestAccountCubit(super.state);

  void set(AccountState state) => emit(state);
}

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

MetadataPluginLoadedState testLoadedState({String pluginName = 'Test Provider'}) =>
    MetadataPluginLoadedState(manifest: testPluginManifest(name: pluginName));

AccountState testAccountState({bool isAuthenticated = false, String? userName}) =>
    AccountState(isAuthenticated: isAuthenticated, userName: userName);

MetadataPluginCubit buildMockMetadataPluginCubit({MetadataPluginState? state}) {
  final cubit = MockMetadataPluginCubit();
  when(() => cubit.state).thenReturn(state ?? testLoadedState());
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  return cubit;
}

AccountCubit buildMockAccountCubit({
  AccountState? state,
  Future<AuthResult> Function()? onSignIn,
  Future<void> Function()? onSignOut,
}) {
  final cubit = MockAccountCubit();
  when(() => cubit.state).thenReturn(state ?? testAccountState());
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.signIn()).thenAnswer(
    (_) async => onSignIn == null
        ? AuthResult.authenticated
        : await onSignIn(),
  );
  when(() => cubit.signOut()).thenAnswer((_) async {
    await onSignOut?.call();
  });
  return cubit;
}
