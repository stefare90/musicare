import 'dart:typed_data';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_discovery_state.dart';

class PluginDiscoveryCubit extends SafeCubit<PluginDiscoveryState> {
  final PluginDiscoveryService _discoveryService;

  PluginDiscoveryCubit(this._discoveryService)
    : super(PluginDiscoveryInitialState());

  Future<void> fetchCommunityPlugins() async {
    emit(PluginDiscoveryLoadingState());
    try {
      final plugins = await _discoveryService.fetchCommunityPlugins();
      emit(PluginDiscoveryLoadedState(plugins));
    } catch (e) {
      emit(PluginDiscoveryErrorState(e));
    }
  }

  Uint8List? getZipBytesForPlugin(PluginManifest manifest) {
    return _discoveryService.getZipBytesForPlugin(manifest);
  }
}
