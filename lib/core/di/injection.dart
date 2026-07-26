import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/inetwork_service.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/istorage_service.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iui_service.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/features/plugin/data/services/plugin_network_service.dart';
import 'package:music_are/features/plugin/data/services/plugin_storage_service.dart';
import 'package:music_are/features/plugin/data/services/plugin_ui_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<GlobalKey<NavigatorState>>(() => rootNavigatorKey);
  sl.registerLazySingleton<INetworkService>(() => PluginNetworkService());
  sl.registerLazySingleton<IStorageService>(
    () => StorageService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<IUIService>(
    () => PluginUiService(navigatorKey: sl<GlobalKey<NavigatorState>>()),
  );
}
