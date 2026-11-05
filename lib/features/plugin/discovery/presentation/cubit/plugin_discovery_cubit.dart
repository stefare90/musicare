import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';

class PluginDiscoveryCubit extends SafeCubit<PluginDiscoveryState> {
  final PluginCatalog _catalog;

  PluginDiscoveryCubit(this._catalog) : super(PluginDiscoveryInitialState());

  Future<void> fetchPlugins({
    PluginType? type,
    bool forceRefresh = false,
  }) async {
    if (state is! PluginDiscoveryLoadedState || forceRefresh) {
      emit(PluginDiscoveryLoadingState());
    }
    try {
      if (forceRefresh) await _catalog.reload();
      final manifests = type == null
          ? <String, PluginManifest>{}
          : await _catalog.latest(type);
      emit(PluginDiscoveryLoadedState(manifests));
    } catch (e) {
      emit(PluginDiscoveryErrorState(e));
    }
  }
}
