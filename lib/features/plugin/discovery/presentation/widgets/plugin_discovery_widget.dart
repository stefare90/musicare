import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_cubit.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_state.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_manifest_card.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_version.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';

typedef PluginSelectedCallback = Future<void> Function(PluginManifest manifest);

class PluginDiscoveryWidget extends StatelessWidget {
  final PluginType? pluginType;
  final PluginManifest? installed;
  final PluginSelectedCallback? onSelected;

  const PluginDiscoveryWidget({
    super.key,
    this.pluginType,
    this.installed,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PluginDiscoveryCubit>(
      create: (context) => PluginDiscoveryCubit(sl<PluginCatalog>())
        ..fetchPlugins(type: pluginType),
      child: _PluginDiscoveryView(
        pluginType: pluginType,
        installed: installed,
        onSelected: onSelected,
      ),
    );
  }
}

class _PluginDiscoveryView extends StatelessWidget {
  final PluginType? pluginType;
  final PluginManifest? installed;
  final PluginSelectedCallback? onSelected;

  const _PluginDiscoveryView({
    this.pluginType,
    this.installed,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.communityPluginsHeader,
              style: context.textTheme.titleMedium,
            ),
            IconButton(
              onPressed: () {
                context.read<PluginDiscoveryCubit>().fetchPlugins(
                  type: pluginType,
                  forceRefresh: true,
                );
              },
              icon: const Icon(Icons.refresh),
              tooltip: context.l10n.retry,
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<PluginDiscoveryCubit, PluginDiscoveryState>(
          builder: (context, catalogState) {
            if (catalogState is PluginDiscoveryLoadingState) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (catalogState is PluginDiscoveryErrorState) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        catalogState.error.toLocalizedString(context),
                        style: const TextStyle(),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<PluginDiscoveryCubit>().fetchPlugins(
                            type: pluginType,
                            forceRefresh: true,
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (catalogState is PluginDiscoveryLoadedState) {
              if (catalogState.plugins.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      context.l10n.noPluginsFound,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: catalogState.plugins.values.map((manifest) {
                  final action = _actionFor(manifest);
                  return PluginManifestCard(
                    manifest: manifest,
                    isActive: manifest.id == installed?.id,
                    action: action,
                    onAction: onSelected == null
                        ? null
                        : () => _runAction(context, manifest, action),
                  );
                }).toList(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  PluginAction _actionFor(PluginManifest manifest) {
    final current = installed;
    if (current == null) return PluginAction.install;
    if (manifest.id != current.id) return PluginAction.replace;
    final comparison = comparePluginVersions(
      manifest.version,
      current.version,
    );
    return (comparison ?? 0) > 0
        ? PluginAction.update
        : PluginAction.reinstall;
  }

  Future<void> _runAction(
    BuildContext context,
    PluginManifest manifest,
    PluginAction action,
  ) async {
    if (action == PluginAction.replace) {
      final confirmed = await Dialogs.confirm(
        context,
        title: context.l10n.pluginReplaceTitle,
        message: context.l10n.pluginReplaceMessage(manifest.name),
        confirmLabel: context.l10n.pluginActionReplace,
      );
      if (!confirmed) return;
    }
    await onSelected?.call(manifest);
  }
}
