import 'package:flutter/material.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';

abstract class AppInitializer {
  /// Orchestrates full application startup and returns the initial route location.
  static Future<String> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Platform services
    await AudioPlayerService.initBackground();

    // 2. Dependency injection
    await initDependencies();

    // 3. Initialize plugin state machines
    final metadataCubit = sl<MetadataPluginCubit>();
    final audioSourceCubit = sl<AudioSourcePluginCubit>();

    await metadataCubit.initialize();
    await audioSourceCubit.initialize();

    return _determineInitialLocation(
      metadataState: metadataCubit.state,
      audioSourceState: audioSourceCubit.state,
    );
  }

  static String _determineInitialLocation({
    required MetadataPluginState metadataState,
    required AudioSourcePluginState audioSourceState,
  }) {
    if (metadataState is MetadataPluginIncompatibleState) {
      return '/plugin-update';
    }
    if (metadataState is MetadataPluginLoadedState &&
        audioSourceState is AudioSourcePluginLoadedState) {
      return '/';
    }
    return '/welcome';
  }
}
