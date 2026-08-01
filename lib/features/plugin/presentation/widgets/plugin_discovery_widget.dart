import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_discovery_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_discovery_state.dart';
import 'package:music_are/features/plugin/presentation/utils/exception_localizer.dart';

class PluginDiscoveryWidget extends StatelessWidget {
  const PluginDiscoveryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PluginDiscoveryCubit>(
      create: (context) =>
          PluginDiscoveryCubit(sl<PluginDiscoveryService>())
            ..fetchCommunityPlugins(),
      child: const _PluginDiscoveryView(),
    );
  }
}

class _PluginDiscoveryView extends StatelessWidget {
  const _PluginDiscoveryView();

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
                context.read<PluginDiscoveryCubit>().fetchCommunityPlugins();
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
                              .fetchCommunityPlugins();
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
                  return _PluginManifestCard(manifest: manifest);
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

class _PluginManifestCard extends StatelessWidget {
  final PluginManifest manifest;

  const _PluginManifestCard({required this.manifest});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<PluginCubit>().installDiscoveredPlugin(manifest);
                },
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
