import 'dart:typed_data';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class PluginDiscoveryCubit extends SafeCubit<PluginDiscoveryState> {
  final PluginDiscoveryService _discoveryService;

  PluginDiscoveryCubit(this._discoveryService)
    : super(PluginDiscoveryInitialState());

  Future<void> fetchCommunityPlugins({
    PluginType? type,
    bool forceRefresh = false,
  }) async {
    if (state is! PluginDiscoveryLoadedState || forceRefresh) {
      emit(PluginDiscoveryLoadingState());
    }
    try {
      final plugins = await _discoveryService.fetchCommunityPlugins(
        type: type,
        forceRefresh: forceRefresh,
      );
      emit(PluginDiscoveryLoadedState(plugins));
    } catch (e) {
      emit(PluginDiscoveryErrorState(e));
    }
  }

  Uint8List? getZipBytesForPlugin(PluginManifest manifest) {
    return _discoveryService.getZipBytesForPlugin(manifest);
  }
}
