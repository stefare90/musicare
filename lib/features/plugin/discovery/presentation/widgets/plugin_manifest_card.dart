import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class PluginManifestCard extends StatelessWidget {
  final PluginManifest manifest;
  final bool isActive;
  final void Function(PluginManifest manifest)? onInstallTap;

  const PluginManifestCard({
    super.key,
    required this.manifest,
    this.isActive = false,
    this.onInstallTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? context.colorScheme.primary
              : context.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: isActive ? 1.5 : 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    manifest.name,
                    style: context.textTheme.titleLarge,
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.activeLabel,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Chip(
                    label: Text('v${manifest.version}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('By ${manifest.author}', style: context.textTheme.labelSmall),
            const SizedBox(height: 12),
            Text(manifest.description, style: context.textTheme.bodyMedium),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isActive
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(context.l10n.activeLabel),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => onInstallTap?.call(manifest),
                      icon: const Icon(Icons.download),
                      label: Text(context.l10n.installAndActivate),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
