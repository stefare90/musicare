import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/services/app_initializer.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';

void main() async {
  final initialLocation = await AppInitializer.initialize();
  runApp(MusicAreApp(initialLocation: initialLocation));
}

class MusicAreApp extends StatelessWidget {
  final String initialLocation;

  const MusicAreApp({super.key, required this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MetadataPluginCubit>.value(
          value: sl<MetadataPluginCubit>(),
        ),
        BlocProvider<AudioSourcePluginCubit>.value(
          value: sl<AudioSourcePluginCubit>(),
        ),
        BlocProvider<PlayerCubit>.value(value: sl<PlayerCubit>()),
      ],
      child: MaterialApp.router(
        title: 'MusicAre',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        builder: (context, child) => NoticeListener(
          notices: sl<NoticeBus>().notices,
          child: child ?? const SizedBox.shrink(),
        ),
        routerConfig: createRouter(initialLocation: initialLocation),
      ),
    );
  }
}
