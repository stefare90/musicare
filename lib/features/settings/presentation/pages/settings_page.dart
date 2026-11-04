import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/player/presentation/cubit/playback_settings_cubit.dart';
import 'package:music_are/features/settings/presentation/widgets/settings/about_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings/accent_color_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings/amoled_black_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings/app_version_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings/infinite_music_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings/language_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings/plugin_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings/theme_mode_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider<PlaybackSettingsCubit>(
      create: (_) => PlaybackSettingsCubit(sl<PreferencesService>()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24.0),
          children: [
            SettingsSectionHeader(label: l10n.settingsAppearanceSection),
            const ThemeModeTile(),
            const AccentColorTile(),
            const AmoledBlackTile(),
            SettingsSectionHeader(label: l10n.settingsPlaybackSection),
            const InfiniteMusicTile(),
            SettingsSectionHeader(label: l10n.settingsPluginsSection),
            const _PluginTiles(),
            SettingsSectionHeader(label: l10n.settingsLanguageSection),
            const LanguageTile(),
            SettingsSectionHeader(label: l10n.settingsApplicationSection),
            const AppVersionTile(),
            const AboutTile(),
          ],
        ),
      ),
    );
  }
}

class _PluginTiles extends StatefulWidget {
  const _PluginTiles();

  @override
  State<_PluginTiles> createState() => _PluginTilesState();
}

class _PluginTilesState extends State<_PluginTiles> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PluginManagerCubit>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PluginManagerCubit, PluginManagerState>(
      builder: (context, state) {
        final plugins = context.watch<PluginSessionCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in PluginType.values)
              PluginTile(
                type: type,
                manifest:
                    state.slot(type).installed ?? plugins.manifestOf(type),
                slot: state.slot(type),
              ),
          ],
        );
      },
    );
  }
}
