import 'dart:typed_data';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

/// Outcome of an interactive sign-in attempt.
///
/// [cancelled] and [failed] are deliberately distinct: cancelling the provider
/// form is a normal user choice that must stay silent, while a failure (wrong
/// token, offline) deserves feedback.
enum AuthResult { authenticated, cancelled, failed }

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
        await _emitLoaded(_pluginEngine.metadataManifest!);
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

      await _emitLoaded(manifest);
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

      await _emitLoaded(manifest);
    } catch (e) {
      emit(MetadataPluginErrorState(e));
    }
  }

  Future<AuthResult> authenticate() async {
    if (state is! MetadataPluginLoadedState) return AuthResult.failed;

    try {
      await _pluginEngine.metadata.auth.authenticate();
      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();
      final userName = isAuth ? await _fetchUserName() : null;

      final currentState = state as MetadataPluginLoadedState;
      emit(
        MetadataPluginLoadedState(
          manifest: currentState.manifest,
          isAuthenticated: isAuth,
          userName: userName,
        ),
      );
      return isAuth ? AuthResult.authenticated : AuthResult.cancelled;
    } catch (_) {
      // Keep the active loaded state on auth error.
      return AuthResult.failed;
    }
  }

  Future<void> logout() async {
    if (state is! MetadataPluginLoadedState) return;

    try {
      await _pluginEngine.metadata.auth.logout();
      final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();

      final currentState = state as MetadataPluginLoadedState;
      emit(
        MetadataPluginLoadedState(
          manifest: currentState.manifest,
          isAuthenticated: isAuth,
        ),
      );
    } catch (e) {
      // Keep active loaded state
    }
  }

  Future<void> unload() async {
    _pluginEngine.unloadMetadata();
    await _preferences.removeActivePluginId();
    emit(MetadataPluginNotConfiguredState());
  }

  Future<void> _emitLoaded(PluginManifest manifest) async {
    final isAuth = await _pluginEngine.metadata.auth.isAuthenticated();
    final userName = isAuth ? await _fetchUserName() : null;
    emit(
      MetadataPluginLoadedState(
        manifest: manifest,
        isAuthenticated: isAuth,
        userName: userName,
      ),
    );
  }

  Future<String?> _fetchUserName() async {
    try {
      final me = await _pluginEngine.metadata.user.me();
      final userId = me['user_id'];
      return userId is String && userId.isNotEmpty ? userId : null;
    } catch (_) {
      return null;
    }
  }
}
