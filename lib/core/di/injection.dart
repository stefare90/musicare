import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/services/network_service.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/browse_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/search_repository.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_lifecycle.dart';
import 'package:music_are/features/plugin/catalog/data/services/github_topic_catalog.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';
import 'package:music_are/features/plugin/management/data/services/plugin_manager.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_entry.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_registry.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_auth.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_lifecycle.dart';
import 'package:music_are/features/plugin/metadata/presentation/services/metadata_auth_presenter.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  sl.registerLazySingleton<NoticeBus>(() => NoticeBus());
  sl.registerLazySingleton<PreferencesService>(
    () => PreferencesService(sharedPreferences),
  );
  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(sl<PreferencesService>()),
  );

  final runtimeHost = RuntimeHost();
  await runtimeHost.start();

  sl.registerLazySingleton<MetadataPluginEngine>(
    () => MetadataPluginEngine(
      client: MetadataClient(
        baseUri: Uri.parse(
          'http://127.0.0.1:${runtimeHost.portOf(Subsystem.metadata)}',
        ),
      ),
      authPresenter: MetadataAuthPresenterImpl(navigatorKey: rootNavigatorKey),
    ),
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
  sl.registerLazySingleton<AudioSourcePluginEngine>(
    () => AudioSourcePluginEngine(
      client: AudioSourceClient(
        baseUri: Uri.parse(
          'http://127.0.0.1:${runtimeHost.portOf(Subsystem.audio)}',
        ),
      ),
    ),
  );
  sl.registerLazySingleton<MetadataPluginLifecycle>(
    () => MetadataPluginLifecycle(sl<MetadataPluginEngine>()),
  );
  sl.registerLazySingleton<MetadataPluginAuth>(
    () => MetadataPluginAuth(
      sl<MetadataPluginEngine>(),
      sl<PreferencesService>(),
    ),
  );
  sl.registerLazySingleton<AudioSourcePluginLifecycle>(
    () => AudioSourcePluginLifecycle(sl<AudioSourcePluginEngine>()),
  );
  sl.registerLazySingleton<PluginRegistry>(
    () => PluginRegistry([
      PluginEntry(
        lifecycle: sl<MetadataPluginLifecycle>(),
        auth: sl<MetadataPluginAuth>(),
      ),
      PluginEntry(lifecycle: sl<AudioSourcePluginLifecycle>()),
    ]),
  );
  sl.registerLazySingleton<PluginCatalog>(
    () => GitHubTopicCatalog(networkService: NetworkService()),
  );
  sl.registerLazySingleton<PluginManager>(
    () => PluginManager(
      registry: sl<PluginRegistry>(),
      catalog: sl<PluginCatalog>(),
      storage: PluginStorage(),
      preferences: sl<PreferencesService>(),
    ),
  );
  sl.registerLazySingleton<PluginSessionCubit>(
    () => PluginSessionCubit(sl<PluginRegistry>(), sl<NoticeBus>()),
  );
  sl.registerLazySingleton<AudioPlayerService>(
    () => AudioPlayerService(
      driver: AudioPlayerDriver(),
      resolver: AudioStreamResolver(sl<AudioSourcePluginEngine>()),
    ),
  );
  sl.registerLazySingleton<PlayerCubit>(
    () => PlayerCubit(
      sl<AudioPlayerService>(),
      sl<NoticeBus>(),
      media: sl<MediaRepository>(),
      user: sl<UserSession>(),
      preferences: sl<PreferencesService>(),
    ),
  );
  sl.registerLazySingleton<UserCubit>(
    () => UserCubit(
      sl<MetadataPluginAuth>(),
      sl<LibraryRepository>(),
      sl<NoticeBus>(),
      sl<PlaylistRepository>(),
    ),
  );
  sl.registerLazySingleton<PluginManagerCubit>(
    () => PluginManagerCubit(sl<PluginManager>(), sl<NoticeBus>()),
  );
  sl.registerLazySingleton<UserSession>(() => sl<UserCubit>());
  sl.registerLazySingleton<UserFavorites>(() => sl<UserCubit>());
  sl.registerLazySingleton<UserSavedMediaIndex>(() => sl<UserCubit>());
  sl.registerLazySingleton<UserPlaylistEdits>(() => sl<UserCubit>());
}
