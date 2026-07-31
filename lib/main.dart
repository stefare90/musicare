import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_discovery_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  final pluginCubit = sl<PluginCubit>();
  await pluginCubit.initialize();
  final String initialLocation = pluginCubit.state is PluginNotConfiguredState
      ? '/select-plugin'
      : '/';
  runApp(
    MusicAreApp(pluginCubit: pluginCubit, initialLocation: initialLocation),
  );
}

class MusicAreApp extends StatelessWidget {
  final PluginCubit pluginCubit;
  final String initialLocation;

  const MusicAreApp({
    super.key,
    required this.pluginCubit,
    required this.initialLocation,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PluginCubit>.value(value: pluginCubit),
        BlocProvider<PluginDiscoveryCubit>(
          create: (context) => PluginDiscoveryCubit(sl()),
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
