import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.musicare.audio',
    androidNotificationChannelName: 'MusicAre Playback',
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  final metadataCubit = sl<MetadataPluginCubit>();
  final audioSourceCubit = sl<AudioSourcePluginCubit>();

  await metadataCubit.initialize();
  await audioSourceCubit.initialize();

  final String initialLocation;
  if (metadataCubit.state is MetadataPluginIncompatibleState) {
    initialLocation = '/plugin-update';
  } else if (metadataCubit.state is MetadataPluginLoadedState &&
      audioSourceCubit.state is AudioSourcePluginLoadedState) {
    initialLocation = '/';
  } else {
    initialLocation = '/welcome';
  }

  runApp(
    MusicAreApp(
      metadataPluginCubit: metadataCubit,
      audioSourcePluginCubit: audioSourceCubit,
      initialLocation: initialLocation,
    ),
  );
}

class MusicAreApp extends StatelessWidget {
  final MetadataPluginCubit metadataPluginCubit;
  final AudioSourcePluginCubit audioSourcePluginCubit;
  final String initialLocation;

  const MusicAreApp({
    super.key,
    required this.metadataPluginCubit,
    required this.audioSourcePluginCubit,
    required this.initialLocation,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>.value(value: sl<PlayerCubit>()),
        BlocProvider<MetadataPluginCubit>.value(value: metadataPluginCubit),
        BlocProvider<AudioSourcePluginCubit>.value(
          value: audioSourcePluginCubit,
        ),
      ],
      child: MaterialApp.router(
        title: 'MusicAre',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: createRouter(initialLocation: initialLocation),
      ),
    );
  }
}
