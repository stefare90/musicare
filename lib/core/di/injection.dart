import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/inetwork_service.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/istorage_service.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iui_service.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/services/network_service.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/data/services/sdk_services/plugin_network_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/sdk_services/plugin_storage_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/sdk_services/plugin_ui_service.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<NetworkService>(() => NetworkService());
  sl.registerLazySingleton<PreferencesService>(
    () => PreferencesService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<GlobalKey<NavigatorState>>(() => rootNavigatorKey);
  sl.registerLazySingleton<INetworkService>(() => PluginNetworkService());
  sl.registerLazySingleton<IStorageService>(
    () => StorageService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<IUIService>(
    () => PluginUiService(navigatorKey: sl<GlobalKey<NavigatorState>>()),
  );
  sl.registerLazySingleton<MetadataPluginEngine>(() => MetadataPluginEngine());
  sl.registerLazySingleton<MetadataPluginCubit>(
    () => MetadataPluginCubit(
      sl<MetadataPluginEngine>(),
      sl<PreferencesService>(),
      sl<PluginDiscoveryService>(),
    ),
  );
  sl.registerLazySingleton<PluginDiscoveryService>(
    () => PluginDiscoveryService(networkService: sl<NetworkService>()),
  );
  sl.registerLazySingleton<AudioSourceClient>(() => AudioSourceClient());
  sl.registerLazySingleton<AudioSourcePluginEngine>(
    () => AudioSourcePluginEngine(client: sl<AudioSourceClient>()),
  );
  sl.registerLazySingleton<AudioSourcePluginCubit>(
    () => AudioSourcePluginCubit(
      sl<AudioSourcePluginEngine>(),
      sl<PreferencesService>(),
      sl<PluginDiscoveryService>(),
    ),
  );
  sl.registerLazySingleton<AudioPlayerDriver>(() => AudioPlayerDriver());
  sl.registerLazySingleton<AudioStreamResolver>(
    () => AudioStreamResolver(sl<AudioSourcePluginEngine>()),
  );
  sl.registerLazySingleton<AudioPlayerService>(
    () => AudioPlayerService(
      driver: sl<AudioPlayerDriver>(),
      resolver: sl<AudioStreamResolver>(),
    ),
  );
  sl.registerLazySingleton<PlayerCubit>(
    () => PlayerCubit(audioService: sl<AudioPlayerService>()),
  );
}
