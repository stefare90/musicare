import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/services/network_service.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_index.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/account_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/browse_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/plugin_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/search_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/services/metadata_auth_presenter.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<NoticeBus>(() => NoticeBus());
  sl.registerLazySingleton<NetworkService>(() => NetworkService());
  sl.registerLazySingleton<PreferencesService>(
    () => PreferencesService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<GlobalKey<NavigatorState>>(() => rootNavigatorKey);

  final runtimeHost = RuntimeHost();
  sl.registerSingleton<RuntimeHost>(runtimeHost);
  await runtimeHost.start();

  sl.registerLazySingleton<MetadataClient>(
    () => MetadataClient(
      baseUri: Uri.parse(
        'http://127.0.0.1:${runtimeHost.portOf(Subsystem.metadata)}',
      ),
    ),
  );
  sl.registerLazySingleton<AudioSourceClient>(
    () => AudioSourceClient(
      baseUri: Uri.parse(
        'http://127.0.0.1:${runtimeHost.portOf(Subsystem.audio)}',
      ),
    ),
  );

  sl.registerLazySingleton<MetadataAuthPresenter>(
    () => MetadataAuthPresenterImpl(
      navigatorKey: sl<GlobalKey<NavigatorState>>(),
    ),
  );
  sl.registerLazySingleton<MetadataPluginEngine>(
    () => MetadataPluginEngine(
      client: sl<MetadataClient>(),
      authPresenter: sl<MetadataAuthPresenter>(),
    ),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepository(sl<MetadataPluginEngine>()),
  );
  sl.registerLazySingleton<PluginRepository>(
    () => PluginRepository(sl<MetadataPluginEngine>()),
  );
  sl.registerLazySingleton<LibraryRepository>(
    () => LibraryRepository(sl<MetadataPluginEngine>()),
  );
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepository(sl<MetadataPluginEngine>()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepository(sl<MetadataPluginEngine>()),
  );
  sl.registerLazySingleton<BrowseRepository>(
    () => BrowseRepository(sl<MetadataPluginEngine>()),
  );
  sl.registerLazySingleton<MediaRepository>(
    () => MediaRepository(sl<MetadataPluginEngine>()),
  );
  sl.registerLazySingleton<MetadataPluginCubit>(
    () => MetadataPluginCubit(
      sl<PluginRepository>(),
      sl<PreferencesService>(),
      sl<PluginDiscoveryService>(),
    ),
  );
  sl.registerLazySingleton<PluginDiscoveryService>(
    () => PluginDiscoveryService(networkService: sl<NetworkService>()),
  );
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
  sl.registerLazySingleton<AccountCubit>(
    () => AccountCubit(sl<AccountRepository>()),
  );
  sl.registerLazySingleton<SavedMediaCubit>(
    () => SavedMediaCubit(
      sl<LibraryRepository>(),
      sl<NoticeBus>(),
      session: sl<AccountCubit>(),
    ),
  );
  sl.registerLazySingleton<SavedMediaIndex>(() => sl<SavedMediaCubit>());
}
