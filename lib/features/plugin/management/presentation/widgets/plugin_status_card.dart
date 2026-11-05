import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_lifecycle_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';

class PluginStatusCard extends StatelessWidget {
  final PluginLifecycleStatus status;
  final PluginType type;
  final PluginManifest? manifest;

  const PluginStatusCard({
    super.key,
    required this.status,
    required this.type,
    this.manifest,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final incompatible = status == PluginLifecycleStatus.incompatible;
    final failed = status == PluginLifecycleStatus.error;
    final blocked = incompatible || failed;
    final accent = blocked ? scheme.error : context.semanticColors.warning;
    final tint = blocked
        ? scheme.errorContainer
        : context.semanticColors.warningContainer;
    final installed = manifest;

    return Container(
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.only(bottom: 25.0),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: blocked ? 0.2 : 0.18),
        border: Border.all(
          color: blocked ? tint : accent.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Icon(_icon(incompatible, failed), size: 50, color: accent),
          const SizedBox(height: 16),
          Text(
            _badge(l10n, incompatible, failed),
            style: context.textTheme.labelLarge?.copyWith(
              color: accent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            type.toLocalizedString(context),
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (blocked && installed != null) ...[
            const SizedBox(height: 4),
            Text(
              installed.name,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.installedVersion(installed.version),
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _message(l10n, incompatible, failed),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  IconData _icon(bool incompatible, bool failed) {
    if (incompatible) return Icons.system_update_alt_rounded;
    if (failed) return Icons.report_gmailerrorred_rounded;
    return Icons.extension_off_rounded;
  }

  String _badge(
    AppLocalizations l10n,
    bool incompatible,
    bool failed,
  ) {
    if (incompatible) return l10n.obsoleteProviderLabel;
    if (failed) return l10n.pluginSetupLoadFailed;
    return l10n.pluginSetupNotInstalled;
  }

  String _message(
    AppLocalizations l10n,
    bool incompatible,
    bool failed,
  ) {
    if (incompatible) return l10n.providerIncompatibleMessage;
    if (failed) return l10n.pluginSetupLoadFailedMessage;
    return _neededMessage(l10n);
  }

  String _neededMessage(AppLocalizations l10n) => switch (type) {
    PluginType.metadata => l10n.pluginSetupMetadataNeeded,
    PluginType.audioSource => l10n.pluginSetupAudioSourceNeeded,
  };
}
