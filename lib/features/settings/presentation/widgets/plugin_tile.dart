import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_icon.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';

class PluginTile extends StatelessWidget {
  final PluginType type;
  final PluginManifest? manifest;

  const PluginTile({super.key, required this.type, this.manifest});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plugin = manifest;

    return ListTile(
      leading: Icon(type.icon),
      title: Text(plugin?.name ?? type.toLocalizedString(context)),
      subtitle: Text(
        plugin == null
            ? l10n.settingsNotConfigured
            : '${type.toLocalizedString(context)} · v${plugin.version}',
      ),
      trailing: plugin == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: plugin == null
          ? null
          : () => AppNavigator.toPluginDetail(context, type),
    );
  }
}
