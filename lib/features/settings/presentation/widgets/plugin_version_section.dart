import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';

/// Installed and SDK versions of a plugin.
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
        _InfoRow(
          label: l10n.pluginVersionInstalled,
          value: 'v${manifest.version}',
        ),
        _InfoRow(
          label: l10n.pluginVersionSdk,
          value: manifest.pluginSdkVersion,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
