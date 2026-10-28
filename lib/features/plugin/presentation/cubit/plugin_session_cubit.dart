import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_state.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_registry.dart';
export 'package:music_are/features/plugin/presentation/cubit/plugin_session_state.dart';

class PluginSessionCubit extends Cubit<PluginSessionState> {
  PluginSessionCubit(this._registry, this._notices)
    : super(
        PluginSessionState(
          {
            for (final entry in _registry.entries)
              entry.type: entry.lifecycle.state,
          },
          authStates: {
            for (final entry in _registry.entries)
              if (entry.auth != null) entry.type: entry.auth!.authState,
          },
        ),
      ) {
    for (final entry in _registry.entries) {
      _subscriptions.add(
        entry.lifecycle.changes.listen(
          (state) => _onLifecycle(entry.type, state),
        ),
      );
      final auth = entry.auth;
      if (auth != null) {
        _subscriptions.add(
          auth.authChanges.listen((state) => _onAuth(entry.type, state)),
        );
      }
    }
  }

  final PluginRegistry _registry;
  final NoticeBus _notices;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  PluginLifecycleState stateOf(PluginType type) => state.stateOf(type);

  PluginAuthState authOf(PluginType type) => state.authOf(type);

  PluginManifest? manifestOf(PluginType type) => stateOf(type).manifest;

  bool isLoaded(PluginType type) => stateOf(type).isLoaded;

  bool hasAuth(PluginType type) => _registry.entryOf(type).auth != null;

  Future<void> signIn(PluginType type) async {
    final auth = _registry.entryOf(type).auth;
    if (auth == null) return;
    try {
      await auth.authenticate();
    } catch (error) {
      _notices.emit(Notice.error(error));
    } finally {
      _onAuth(type, auth.authState);
    }
  }

  Future<void> signOut(PluginType type) async {
    final auth = _registry.entryOf(type).auth;
    if (auth == null) return;
    try {
      await auth.logout();
    } catch (error) {
      _notices.emit(Notice.error(error));
    } finally {
      _onAuth(type, auth.authState);
    }
  }

  Future<void> refreshAuth(PluginType type) async {
    final auth = _registry.entryOf(type).auth;
    if (auth == null) return;
    try {
      await auth.refresh();
    } catch (error) {
      _notices.emit(Notice.error(error));
    } finally {
      _onAuth(type, auth.authState);
    }
  }

  void _onLifecycle(PluginType type, PluginLifecycleState lifecycleState) {
    if (isClosed) return;
    emit(
      PluginSessionState({
        ...state.states,
        type: lifecycleState,
      }, authStates: state.authStates),
    );
  }

  void _onAuth(PluginType type, PluginAuthState authState) {
    if (isClosed) return;
    emit(
      PluginSessionState(
        state.states,
        authStates: {...state.authStates, type: authState},
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
