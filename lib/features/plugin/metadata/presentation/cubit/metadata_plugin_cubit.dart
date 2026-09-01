import 'dart:typed_data';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class MetadataPluginCubit extends SafeCubit<MetadataPluginState> {
  final MetadataPluginEngine _pluginEngine;
  final PreferencesService _preferences;
  final PluginDiscoveryService _discoveryService;

  MetadataPluginCubit(
    this._pluginEngine,
    this._preferences,
    this._discoveryService,
  ) : super(MetadataPluginInitialState());

  Future<void> initialize() async {
    emit(MetadataPluginLoadingState());
    try {
      final savedPluginId = _preferences.getActivePluginId();

      if (savedPluginId != null &&
          await _pluginEngine.isPluginInstalledOnDisk(savedPluginId)) {
        await _pluginEngine.loadFromDisk(savedPluginId);
        final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();

        emit(
          MetadataPluginLoadedState(
            manifest: _pluginEngine.metadataManifest!,
            isAuthenticated: isAuth,
          ),
        );
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
      await _pluginEngine.loadFromZipBytes(zipBytes);
      final manifest = _pluginEngine.metadataManifest!;

      await _preferences.setActivePluginId(manifest.id);

      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();
      emit(
        MetadataPluginLoadedState(manifest: manifest, isAuthenticated: isAuth),
      );
    } catch (e) {
      emit(MetadataPluginErrorState(e));
    }
  }

  Future<void> loadFromDisk(String pluginId) async {
    emit(MetadataPluginLoadingState());
    try {
      await _pluginEngine.loadFromDisk(pluginId);
      final manifest = _pluginEngine.metadataManifest!;

      await _preferences.setActivePluginId(manifest.id);

      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();
      emit(
        MetadataPluginLoadedState(manifest: manifest, isAuthenticated: isAuth),
      );
    } catch (e) {
      emit(MetadataPluginErrorState(e));
    }
  }

  Future<void> authenticate() async {
    if (state is! MetadataPluginLoadedState) return;

    try {
      await _pluginEngine.metadata.auth.authenticate();
      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();

      final currentState = state as MetadataPluginLoadedState;
      emit(currentState.copyWith(isAuthenticated: isAuth));
    } catch (e) {
      // Keep active loaded state on auth error
    }
  }

  Future<void> logout() async {
    if (state is! MetadataPluginLoadedState) return;

    try {
      await _pluginEngine.metadata.auth.logout();
      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();

      final currentState = state as MetadataPluginLoadedState;
      emit(currentState.copyWith(isAuthenticated: isAuth));
    } catch (e) {
      // Keep active loaded state
    }
  }

  Future<void> unload() async {
    _pluginEngine.unloadMetadata();
    await _preferences.removeActivePluginId();
    emit(MetadataPluginNotConfiguredState());
  }
}
