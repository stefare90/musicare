import 'package:flutter/material.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';

abstract class AppInitializer {
  static Future<String> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize native platform audio background services
    await AudioPlayerDriver.initBackground();

    // Initialize Dependency Injection container
    await initDependencies();

    // Initialize plugins
    final metadataCubit = sl<MetadataPluginCubit>();
    final audioSourceCubit = sl<AudioSourcePluginCubit>();

    await metadataCubit.initialize();
    await audioSourceCubit.initialize();
    await sl<UserCubit>().initialize();

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
