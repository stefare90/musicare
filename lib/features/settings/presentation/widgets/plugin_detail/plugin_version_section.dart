import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_info_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';

class PluginVersionSection extends StatelessWidget {
  final PluginManifest manifest;

  const PluginVersionSection({super.key, required this.manifest});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(label: l10n.pluginVersionSection),
        SettingsInfoTile(
          label: l10n.pluginVersionInstalled,
          value: 'v${manifest.version}',
        ),
        SettingsInfoTile(
          label: l10n.pluginVersionSdk,
          value: manifest.pluginSdkVersion,
        ),
      ],
    );
  }
}
