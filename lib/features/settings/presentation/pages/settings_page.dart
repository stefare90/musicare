import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/settings/presentation/widgets/accent_color_section.dart';
import 'package:music_are/features/settings/presentation/widgets/amoled_black_switch.dart';
import 'package:music_are/features/settings/presentation/widgets/language_section.dart';
import 'package:music_are/features/settings/presentation/widgets/plugin_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:music_are/features/settings/presentation/widgets/theme_mode_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24.0),
        children: [
          SettingsSectionHeader(label: l10n.settingsAppearanceSection),
          const ThemeModeSection(),
          const AccentColorSection(),
          const AmoledBlackSwitch(),
          SettingsSectionHeader(label: l10n.settingsPluginsSection),
          const _MetadataPluginTile(),
          const _AudioSourcePluginTile(),
          SettingsSectionHeader(label: l10n.settingsLanguageSection),
          const LanguageSection(),
          SettingsSectionHeader(label: l10n.settingsAboutSection),
          ListTile(
            title: Text(l10n.settingsAboutTile),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => AppNavigator.toAbout(context),
          ),
        ],
      ),
    );
  }
}

class _MetadataPluginTile extends StatelessWidget {
  const _MetadataPluginTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetadataPluginCubit, MetadataPluginState>(
      builder: (context, state) {
        final manifest = state is MetadataPluginLoadedState
            ? state.manifest
            : null;
        return PluginTile(type: PluginType.metadata, manifest: manifest);
      },
    );
  }
}

class _AudioSourcePluginTile extends StatelessWidget {
  const _AudioSourcePluginTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioSourcePluginCubit, AudioSourcePluginState>(
      builder: (context, state) {
        final manifest = state is AudioSourcePluginLoadedState
            ? state.manifest
            : null;
        return PluginTile(type: PluginType.audioSource, manifest: manifest);
      },
    );
  }
}
