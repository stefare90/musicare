import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/services/app_initializer.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_state.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';

void main() async {
  final initialLocation = await AppInitializer.initialize();
  runApp(MusicAreApp(initialLocation: initialLocation));
}

class MusicAreApp extends StatefulWidget {
  final String initialLocation;

  const MusicAreApp({super.key, required this.initialLocation});

  @override
  State<MusicAreApp> createState() => _MusicAreAppState();
}

class _MusicAreAppState extends State<MusicAreApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

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
        BlocProvider<UserCubit>.value(value: sl<UserCubit>()),
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'MusicAre',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightThemeOf(themeState.accent),
            darkTheme: AppTheme.darkThemeOf(
              themeState.accent,
              amoled: themeState.amoledBlack,
            ),
            themeMode: themeState.themeMode,
            themeAnimationDuration: Duration.zero,
            locale: themeState.locale,
            builder: (context, child) => Scaffold(
              resizeToAvoidBottomInset: false,
              body: NoticeListener(
                notices: sl<NoticeBus>().notices,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
