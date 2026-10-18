import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/features/player/data/services/audio_handler.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';

abstract class AppInitializer {
  static Future<String> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await initDependencies();

    await AudioService.init<MusicAreAudioHandler>(
      builder: () => MusicAreAudioHandler(sl<AudioPlayerService>()),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.musicare.audio',
        androidNotificationChannelName: 'MusicAre Playback',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ),
    );

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
