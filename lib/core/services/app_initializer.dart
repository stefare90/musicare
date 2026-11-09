import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/license/app_license.dart';
import 'package:music_are/features/player/data/services/audio_handler.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/plugin/management/data/services/plugin_manager.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_switch_reset.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/core/services/plugin_startup_route.dart';
import 'package:music_are/features/listening/data/services/listening_tracker.dart';

abstract class AppInitializer {
  static Future<String> initialize() async {
    AppLicense.register();
    WidgetsFlutterBinding.ensureInitialized();

    await initDependencies();

    sl<ListeningTracker>().start();

    await AudioService.init<MusicAreAudioHandler>(
      builder: () => MusicAreAudioHandler(sl<AudioPlayerService>()),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.musicare.audio',
        androidNotificationChannelName: 'MusicAre Playback',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ),
    );

    final manager = sl<PluginManager>();
    sl<PluginSwitchReset>().start();
    await manager.initialize();
    await sl<UserCubit>().initialize();

    return pluginStartupLocation(
      metadataState: manager.pluginState(PluginType.metadata),
      audioState: manager.pluginState(PluginType.audioSource),
    );
  }
}
