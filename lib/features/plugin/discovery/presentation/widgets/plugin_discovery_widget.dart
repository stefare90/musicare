import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_cubit.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_state.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_manifest_card.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';

class PluginDiscoveryWidget extends StatelessWidget {
  final PluginType? pluginType;
  final String? activePluginId;
  final void Function(PluginManifest manifest)? onInstallTap;

  const PluginDiscoveryWidget({
    super.key,
    this.pluginType,
    this.activePluginId,
    this.onInstallTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PluginDiscoveryCubit>(
      create: (context) =>
          PluginDiscoveryCubit(sl<PluginDiscoveryService>())
            ..fetchCommunityPlugins(type: pluginType),
      child: _PluginDiscoveryView(
        pluginType: pluginType,
        activePluginId: activePluginId,
        onInstallTap: onInstallTap,
      ),
    );
  }
}

class _PluginDiscoveryView extends StatelessWidget {
  final PluginType? pluginType;
  final String? activePluginId;
  final void Function(PluginManifest manifest)? onInstallTap;

  const _PluginDiscoveryView({
    this.pluginType,
    this.activePluginId,
    this.onInstallTap,
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
                context.read<PluginDiscoveryCubit>().fetchCommunityPlugins(
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
          builder: (context, discoveryState) {
            if (discoveryState is PluginDiscoveryLoadingState) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (discoveryState is PluginDiscoveryErrorState) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        discoveryState.error.toLocalizedString(context),
                        style: const TextStyle(),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<PluginDiscoveryCubit>()
                              .fetchCommunityPlugins(
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

            if (discoveryState is PluginDiscoveryLoadedState) {
              if (discoveryState.plugins.isEmpty) {
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
                children: discoveryState.plugins.map((manifest) {
                  final isActive = manifest.id == activePluginId;

                  return PluginManifestCard(
                    manifest: manifest,
                    isActive: isActive,
                    onInstallTap: onInstallTap,
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
}
