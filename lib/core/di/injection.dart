import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/errors/error_presentation.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/errors/app_error_presentation.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/services/network_service.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';
import 'package:music_are/features/listening/data/services/listening_tracker.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_history_sink.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/update/data/services/app_update_downloader.dart';
import 'package:music_are/features/update/data/services/app_update_installer.dart';
import 'package:music_are/features/update/data/services/app_update_checker.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';
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
import 'package:music_are/features/plugin/shared/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_runtime_boot.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_entry.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_registry.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_switch_reset.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_auth_controller.dart';
import 'package:music_are/features/plugin/shared/presentation/services/plugin_auth_presenter.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef CoreServices = ({PluginRuntimeBoot boot, PluginStorage storage});

typedef RuntimeServices = ({
  PluginManager manager,
  PluginSwitchReset switchReset,
  ListeningTracker listeningTracker,
  AudioPlayerService audioPlayer,
  UserCubit userCubit,
});

final sl = GetIt.instance;

Future<CoreServices> initCoreDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final preferences = PreferencesService(sharedPreferences);
  final storage = PluginStorage();
  final boot = PluginRuntimeBoot(
    host: RuntimeHost(),
    preferences: preferences,
    storage: storage,
  );

  sl.registerLazySingleton<NoticeBus>(() => NoticeBus());
  sl.registerSingleton<ErrorPresentation>(appErrorPresentation);
  sl.registerSingleton<PreferencesService>(preferences);
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(preferences));

  return (boot: boot, storage: storage);
}

RuntimeServices initRuntimeDependencies(
  RuntimePorts ports,
  PluginStorage storage,
) {
  final notices = sl<NoticeBus>();
  final preferences = sl<PreferencesService>();

  final metadataClient = MetadataClient(
    baseUri: Uri.parse('http://127.0.0.1:${ports.portOf(Subsystem.metadata)}'),
  );
  final audioClient = AudioSourceClient(
    baseUri: Uri.parse('http://127.0.0.1:${ports.portOf(Subsystem.audio)}'),
  );
  final authPresenter = PluginAuthPresenterImpl(navigatorKey: rootNavigatorKey);

  final metadataEngine = MetadataPluginEngine(client: metadataClient);
  final audioEngine = AudioSourcePluginEngine(client: audioClient);

  final metadataLifecycle = MetadataPluginLifecycle(metadataEngine, storage);
  final audioLifecycle = AudioSourcePluginLifecycle(audioEngine, storage);

  final metadataAuth = PluginAuthController(
    available: () => metadataEngine.hasMetadata,
    activePluginId: () => metadataEngine.metadataManifest?.id,
    flow: AuthFlow(
      caller: metadataClient,
      presenter: authPresenter,
      toException: (error) =>
          MetadataPluginException.fromPayload(error.toJson()),
    ),
    preferences: preferences,
    isUnsupported: (error) => error is MetadataUnsupportedException,
  );
  final audioAuth = PluginAuthController(
    available: () => audioEngine.isRunning,
    activePluginId: () => audioEngine.activePluginId,
    flow: AuthFlow(
      caller: audioClient,
      presenter: authPresenter,
      toException: (error) => AudioPluginException.fromPayload(error.toJson()),
    ),
    preferences: preferences,
    isUnsupported: (error) => error is AudioUnsupportedException,
  );

  final registry = PluginRegistry([
    PluginEntry(lifecycle: metadataLifecycle, auth: metadataAuth),
    PluginEntry(lifecycle: audioLifecycle, auth: audioAuth),
  ]);
  final catalog = GitHubTopicCatalog(networkService: NetworkService());
  final manager = PluginManager(
    registry: registry,
    catalog: catalog,
    storage: storage,
    preferences: preferences,
  );
  final audioPlayer = AudioPlayerService(
    driver: AudioPlayerDriver(),
    resolver: AudioStreamResolver(audioEngine),
  );

  sl.registerLazySingleton<LibraryRepository>(
    () => LibraryRepository(metadataEngine),
  );
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepository(metadataEngine),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepository(metadataEngine),
  );
  sl.registerLazySingleton<BrowseRepository>(
    () => BrowseRepository(metadataEngine),
  );
  sl.registerLazySingleton<MediaRepository>(
    () => MediaRepository(metadataEngine),
  );
  final userCubit = UserCubit(
    metadataAuth,
    sl<LibraryRepository>(),
    notices,
    sl<PlaylistRepository>(),
  );
  sl.registerSingleton<UserCubit>(userCubit);
  sl.registerSingleton<UserSession>(userCubit);
  sl.registerSingleton<UserFavorites>(userCubit);
  sl.registerSingleton<UserSavedMediaIndex>(userCubit);
  sl.registerSingleton<UserPlaylistEdits>(userCubit);

  sl.registerSingleton<PluginCatalog>(catalog);
  sl.registerLazySingleton<PluginSessionCubit>(
    () => PluginSessionCubit(registry, notices),
  );
  sl.registerLazySingleton<PluginManagerCubit>(
    () => PluginManagerCubit(manager, notices),
  );
  sl.registerLazySingleton<PlayerCubit>(
    () => PlayerCubit(
      audioPlayer,
      notices,
      media: sl<MediaRepository>(),
      user: userCubit,
      preferences: preferences,
    ),
  );
  sl.registerLazySingleton<AppUpdateCubit>(
    () => AppUpdateCubit(
      AppUpdateChecker(),
      AppUpdateDownloader(),
      AppUpdateInstaller(),
      notices,
    ),
  );

  final listeningTracker = ListeningTracker(
    playback: audioPlayer.playbackDataStream,
    sinks: [MetadataHistorySink(metadataEngine, userCubit)],
  );
  final switchReset = PluginSwitchReset(
    lifecycle: metadataLifecycle.changes,
    onPluginChanged: () async {
      userCubit.reset();
      await audioPlayer.clearQueue();
    },
  );

  return (
    manager: manager,
    switchReset: switchReset,
    listeningTracker: listeningTracker,
    audioPlayer: audioPlayer,
    userCubit: userCubit,
  );
}
