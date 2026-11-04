import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_icon.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';

class PluginTile extends StatelessWidget {
  final PluginType type;
  final PluginManifest? manifest;
  final PluginSlotState? slot;

  const PluginTile({
    super.key,
    required this.type,
    this.manifest,
    this.slot,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plugin = manifest;
    final status = slot;

    return ListTile(
      leading: Icon(type.icon),
      title: Text(plugin?.name ?? type.toLocalizedString(context)),
      subtitle: plugin == null
          ? Text(l10n.settingsNotConfigured)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${type.toLocalizedString(context)} · v${plugin.version}'),
                if (status?.updateAvailable == true &&
                    status?.remote != null)
                  Text(
                    l10n.pluginUpdateAvailable(
                      plugin.version,
                      status!.remote!.version,
                    ),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  )
                else if (status?.incompatible == true)
                  Text(
                    l10n.pluginIncompatible,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
              ],
            ),
      isThreeLine: plugin != null &&
          (status?.updateAvailable == true ||
              status?.incompatible == true),
      trailing: plugin == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: plugin == null
          ? null
          : () => AppNavigator.toPluginDetail(context, type),
    );
  }
}
