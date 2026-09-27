import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_icon.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';

/// Icon, name, author/type line and description of a plugin.
class PluginDetailHeader extends StatelessWidget {
  final PluginManifest manifest;

  const PluginDetailHeader({super.key, required this.manifest});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = manifest.pluginType;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(type?.icon ?? Icons.extension_outlined, size: 40.0),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(manifest.name, style: context.textTheme.titleLarge),
                const SizedBox(height: 2.0),
                Text(
                  type == null
                      ? l10n.byAuthor(manifest.author)
                      : '${l10n.byAuthor(manifest.author)} · '
                            '${type.toLocalizedString(context)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(manifest.description, style: context.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
