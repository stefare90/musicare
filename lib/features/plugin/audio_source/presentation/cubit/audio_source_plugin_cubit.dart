import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class AudioSourcePluginCubit extends SafeCubit<AudioSourcePluginState> {
  final AudioSourcePluginEngine _engine;
  final PreferencesService _preferences;
  final PluginDiscoveryService _discoveryService;

  AudioSourcePluginCubit(
    this._engine,
    this._preferences,
    this._discoveryService,
  ) : super(AudioSourcePluginInitialState());

  Future<void> initialize() async {
    emit(AudioSourcePluginLoadingState());
    try {
      final savedId = _preferences.getActiveAudioSourcePluginId();

      if (savedId != null && await _engine.isPluginInstalledOnDisk(savedId)) {
        await _engine.loadFromDisk(savedId);
        emit(
          AudioSourcePluginLoadedState(
            manifest: _engine.activeManifest!,
            port: _engine.activePort!,
          ),
        );
      } else {
        emit(AudioSourcePluginNotConfiguredState());
      }
    } catch (e) {
      emit(AudioSourcePluginErrorState(e));
    }
  }

  Future<void> installDiscoveredPlugin(PluginManifest manifest) async {
    debugPrint(
      '👉 [Cubit] 1. installDiscoveredPlugin triggered for: ${manifest.name} (${manifest.id})',
    );
    emit(AudioSourcePluginLoadingState());
    try {
      debugPrint('👉 [Cubit] 2. Retrieving zip bytes from DiscoveryService...');
      final zipBytes = _discoveryService.getZipBytesForPlugin(manifest);
      debugPrint(
        '👉 [Cubit] 3. Got ${zipBytes.length} bytes. Passing to loadFromZipBytes...',
      );
      await loadFromZipBytes(zipBytes);
      debugPrint('👉 [Cubit] 4. loadFromZipBytes finished successfully!');
    } catch (e, st) {
      debugPrint('💥 [Cubit] ERROR in installDiscoveredPlugin: $e\n$st');
      emit(AudioSourcePluginErrorState(e));
    }
  }

  Future<void> loadFromZipBytes(Uint8List zipBytes) async {
    if (state is! AudioSourcePluginLoadingState) {
      emit(AudioSourcePluginLoadingState());
    }
    try {
      debugPrint('👉 [Cubit] 5. Calling _engine.loadFromZipBytes...');
      await _engine.loadFromZipBytes(zipBytes);
      final manifest = _engine.activeManifest!;
      debugPrint(
        '👉 [Cubit] 6. Saving active audio source plugin ID: ${manifest.id}',
      );
      await _preferences.setActiveAudioSourcePluginId(manifest.id);

      emit(
        AudioSourcePluginLoadedState(
          manifest: manifest,
          port: _engine.activePort!,
        ),
      );
      debugPrint(
        '👉 [Cubit] 7. Emitted AudioSourcePluginLoadedState on port ${_engine.activePort}',
      );
    } catch (e, st) {
      debugPrint('💥 [Cubit] ERROR in loadFromZipBytes: $e\n$st');
      emit(AudioSourcePluginErrorState(e));
    }
  }

  Future<void> loadFromDisk(String pluginId) async {
    emit(AudioSourcePluginLoadingState());
    try {
      await _engine.loadFromDisk(pluginId);
      final manifest = _engine.activeManifest!;
      await _preferences.setActiveAudioSourcePluginId(manifest.id);

      emit(
        AudioSourcePluginLoadedState(
          manifest: manifest,
          port: _engine.activePort!,
        ),
      );
    } catch (e) {
      emit(AudioSourcePluginErrorState(e));
    }
  }

  Future<ResolvedTrackPlayback> resolveTrack(
    Track track, {
    AudioQuality quality = AudioQuality.high,
  }) {
    return _engine.resolveTrack(track, quality: quality);
  }

  Future<AudioStreamResponse> resolveStream(
    String candidateId, {
    AudioQuality quality = AudioQuality.high,
  }) {
    return _engine.resolveStream(candidateId, quality: quality);
  }

  Future<void> unload() async {
    await _engine.terminate();
    await _preferences.removeActiveAudioSourcePluginId();
    emit(AudioSourcePluginNotConfiguredState());
  }

  @override
  Future<void> close() async {
    await _engine.terminate();
    return super.close();
  }
}
