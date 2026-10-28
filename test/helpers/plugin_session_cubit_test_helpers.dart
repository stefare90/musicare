import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class TestPluginSessionCubit extends Cubit<PluginSessionState>
    implements PluginSessionCubit {
  TestPluginSessionCubit({
    PluginLifecycleState? metadata,
    PluginLifecycleState? audioSource,
    Map<PluginType, PluginAuthState>? authStates,
  }) : super(
         PluginSessionState(
           {
             PluginType.metadata:
                 metadata ?? const PluginLifecycleState.notConfigured(),
             PluginType.audioSource:
                 audioSource ?? const PluginLifecycleState.notConfigured(),
           },
           authStates:
               authStates ??
               {PluginType.metadata: const PluginAuthState.signedOut()},
         ),
       );

  @override
  PluginLifecycleState stateOf(PluginType type) => state.stateOf(type);

  @override
  PluginAuthState authOf(PluginType type) => state.authOf(type);

  @override
  PluginManifest? manifestOf(PluginType type) => stateOf(type).manifest;

  @override
  bool isLoaded(PluginType type) => stateOf(type).isLoaded;

  @override
  bool hasAuth(PluginType type) => state.authStates.containsKey(type);

  void Function(PluginType type)? onSignIn;
  void Function(PluginType type)? onSignOut;
  void Function(PluginType type)? onRefreshAuth;

  @override
  Future<void> signIn(PluginType type) async {
    onSignIn?.call(type);
  }

  @override
  Future<void> signOut(PluginType type) async {
    onSignOut?.call(type);
  }

  @override
  Future<void> refreshAuth(PluginType type) async {
    onRefreshAuth?.call(type);
  }

  void setState(PluginType type, PluginLifecycleState runtimeState) {
    emit(PluginSessionState({...state.states, type: runtimeState}));
  }

  void setAuthState(PluginType type, PluginAuthState authState) {
    emit(
      PluginSessionState(
        state.states,
        authStates: {...state.authStates, type: authState},
      ),
    );
  }
}

TestPluginSessionCubit buildTestPluginSessionCubit({
  PluginLifecycleState? metadata,
  PluginLifecycleState? audioSource,
  Map<PluginType, PluginAuthState>? authStates,
}) => TestPluginSessionCubit(
  metadata: metadata,
  audioSource: audioSource,
  authStates: authStates,
);

PluginLifecycleState testRuntimeLoaded(PluginManifest manifest, {int? port}) =>
    PluginLifecycleState.loaded(manifest, port: port);

PluginLifecycleState testRuntimeIncompatible(PluginManifest manifest) =>
    PluginLifecycleState.incompatible(manifest);

PluginLifecycleState testRuntimeFailure(Object error) =>
    PluginLifecycleState.failure(error);
