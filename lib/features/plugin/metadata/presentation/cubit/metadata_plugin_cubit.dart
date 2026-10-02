import 'dart:typed_data';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/plugin_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

/// Manages the metadata plugin lifecycle (install, load, update, version).
///
/// It owns the plugin, not the user: the account identity lives in `AccountCubit`.
/// Data access goes through [PluginRepository] (lifecycle only).
class MetadataPluginCubit extends SafeCubit<MetadataPluginState> {
  final PluginRepository _plugin;
  final PreferencesService _preferences;
  final PluginDiscoveryService _discoveryService;

  MetadataPluginCubit(
    this._plugin,
    this._preferences,
    this._discoveryService,
  ) : super(MetadataPluginInitialState());

  Future<void> initialize() async {
    emit(MetadataPluginLoadingState());
    try {
      final savedPluginId = _preferences.getActivePluginId();

      if (savedPluginId != null &&
          await _plugin.isInstalledOnDisk(savedPluginId)) {
        await _plugin.loadFromDisk(savedPluginId);
        await _emitLoaded(_plugin.manifest!);
      } else {
        emit(MetadataPluginNotConfiguredState());
      }
    } on IncompatibleSdkVersionException catch (e) {
      emit(MetadataPluginIncompatibleState(e.manifest));
    } catch (e) {
      emit(MetadataPluginErrorState(e));
    }
  }

  Future<void> installDiscoveredPlugin(PluginManifest manifest) async {
    emit(MetadataPluginLoadingState());
    try {
      final zipBytes = _discoveryService.getZipBytesForPlugin(manifest);
      await loadFromZipBytes(zipBytes);
    } catch (e) {
      emit(MetadataPluginErrorState(e));
    }
  }

  Future<void> loadFromZipBytes(Uint8List zipBytes) async {
    if (state is! MetadataPluginLoadingState) {
      emit(MetadataPluginLoadingState());
    }
    try {
      await _plugin.loadFromZipBytes(zipBytes);
      final manifest = _plugin.manifest!;

      await _preferences.setActivePluginId(manifest.id);

      await _emitLoaded(manifest);
    } catch (e) {
      emit(MetadataPluginErrorState(e));
    }
  }

  Future<void> loadFromDisk(String pluginId) async {
    emit(MetadataPluginLoadingState());
    try {
      await _plugin.loadFromDisk(pluginId);
      final manifest = _plugin.manifest!;

      await _preferences.setActivePluginId(manifest.id);

      await _emitLoaded(manifest);
    } catch (e) {
      emit(MetadataPluginErrorState(e));
    }
  }

  Future<void> unload() async {
    _plugin.unload();
    await _preferences.removeActivePluginId();
    emit(MetadataPluginNotConfiguredState());
  }

  Future<void> _emitLoaded(PluginManifest manifest) async {
    emit(MetadataPluginLoadedState(manifest: manifest));
  }
}
