import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class PluginSessionState {
  final Map<PluginType, PluginLifecycleState> states;
  final Map<PluginType, PluginAuthState> authStates;

  const PluginSessionState(this.states, {this.authStates = const {}});

  PluginLifecycleState stateOf(PluginType type) =>
      states[type] ?? const PluginLifecycleState.notConfigured();

  PluginAuthState authOf(PluginType type) =>
      authStates[type] ?? const PluginAuthState.unavailable();
}
