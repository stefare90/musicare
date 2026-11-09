import 'dart:async';

import 'package:music_are/features/plugin/shared/data/models/plugin_lifecycle_state.dart';

class PluginSwitchReset {
  PluginSwitchReset({required this._lifecycle, required this._onPluginChanged});

  final Stream<PluginLifecycleState> _lifecycle;
  final Future<void> Function() _onPluginChanged;
  StreamSubscription<PluginLifecycleState>? _subscription;
  String? _pluginId;

  void start() {
    _subscription ??= _lifecycle.listen(_onState);
  }

  Future<void> _onState(PluginLifecycleState state) async {
    final id = state.manifest?.id;
    if (id == null) return;

    final previous = _pluginId;
    _pluginId = id;
    if (previous == null || previous == id) return;

    await _onPluginChanged();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
