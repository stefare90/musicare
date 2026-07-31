import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_state.dart';

class PluginCubit extends Cubit<PluginState> {
  final PluginEngine _pluginEngine;
  final PreferencesService _preferences;
  final PluginDiscoveryService _discoveryService;

  PluginCubit(this._pluginEngine, this._preferences, this._discoveryService)
    : super(PluginInitialState());

  Future<void> initialize() async {
    emit(PluginLoadingState());
    try {
      final savedPluginId = _preferences.getActivePluginId();

      if (savedPluginId != null &&
          await _pluginEngine.isPluginInstalledOnDisk(savedPluginId)) {
        await _pluginEngine.loadFromDisk(savedPluginId);
        final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();

        emit(
          PluginLoadedState(
            manifest: _pluginEngine.metadataManifest!,
            isAuthenticated: isAuth,
          ),
        );
      } else {
        emit(PluginNotConfiguredState());
      }
    } catch (e) {
      emit(PluginErrorState('Failed to initialize plugin: $e'));
    }
  }

  Future<void> installDiscoveredPlugin(PluginManifest manifest) async {
    final zipBytes = _discoveryService.getZipBytesForPlugin(manifest);

    if (zipBytes == null) {
      emit(PluginErrorState('Plugin binary zip not found in discovery cache.'));
      return;
    }

    await loadFromZipBytes(zipBytes);
  }

  Future<void> loadFromZipBytes(Uint8List zipBytes) async {
    emit(PluginLoadingState());
    try {
      await _pluginEngine.loadFromZipBytes(zipBytes);
      final manifest = _pluginEngine.metadataManifest!;

      await _preferences.setActivePluginId(manifest.id);

      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();
      emit(PluginLoadedState(manifest: manifest, isAuthenticated: isAuth));
    } catch (e) {
      emit(PluginErrorState(e.toString()));
    }
  }

  Future<void> loadFromDisk(String pluginId) async {
    emit(PluginLoadingState());
    try {
      await _pluginEngine.loadFromDisk(pluginId);
      final manifest = _pluginEngine.metadataManifest!;

      await _preferences.setActivePluginId(manifest.id);

      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();
      emit(PluginLoadedState(manifest: manifest, isAuthenticated: isAuth));
    } catch (e) {
      emit(PluginErrorState(e.toString()));
    }
  }

  Future<void> authenticate() async {
    if (state is! PluginLoadedState) return;

    try {
      await _pluginEngine.metadata.auth.authenticate();
      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();

      final currentState = state as PluginLoadedState;
      emit(currentState.copyWith(isAuthenticated: isAuth));
    } catch (e) {
      // Keep active loaded state on auth error
    }
  }

  Future<void> logout() async {
    if (state is! PluginLoadedState) return;

    try {
      await _pluginEngine.metadata.auth.logout();
      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();

      final currentState = state as PluginLoadedState;
      emit(currentState.copyWith(isAuthenticated: isAuth));
    } catch (e) {
      // Keep active loaded state
    }
  }

  Future<void> unload() async {
    _pluginEngine.unloadMetadata();
    await _preferences.removeActivePluginId();
    emit(PluginNotConfiguredState());
  }
}
