import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/license/app_license.dart';
import 'package:music_are/core/services/plugin_startup_route.dart';
import 'package:music_are/features/player/data/services/audio_handler.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

abstract class AppInitializer {
  static Future<String> initialize() async {
    AppLicense.register();
    WidgetsFlutterBinding.ensureInitialized();

    final core = await initCoreDependencies();
    final ports = await core.boot.start();
    final runtime = initRuntimeDependencies(ports, core.storage);

    runtime.listeningTracker.start();

    await AudioService.init<MusicAreAudioHandler>(
      builder: () => MusicAreAudioHandler(runtime.audioPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.musicare.audio',
        androidNotificationChannelName: 'MusicAre Playback',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ),
    );

    runtime.switchReset.start();
    await runtime.manager.initialize();
    await runtime.userCubit.initialize();

    return pluginStartupLocation(
      metadataState: runtime.manager.pluginState(PluginType.metadata),
      audioState: runtime.manager.pluginState(PluginType.audioSource),
    );
  }
}
