import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_discovery_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_discovery_state.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_state.dart';

class PluginSelectionPage extends StatefulWidget {
  const PluginSelectionPage({super.key});

  @override
  State<PluginSelectionPage> createState() => _PluginSelectionPageState();
}

class _PluginSelectionPageState extends State<PluginSelectionPage> {
  @override
  void initState() {
    super.initState();
    context.read<PluginDiscoveryCubit>().fetchCommunityPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.setupTitle), centerTitle: true),
      body: BlocBuilder<PluginCubit, PluginState>(
        builder: (context, pluginState) {
          if (pluginState is PluginLoadingState) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(context.l10n.installingPlugin),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.welcomeTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.selectProviderSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.communityPluginsHeader,
                  style: Theme.of(context).textTheme.titleMedium,
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
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                context.l10n.failedToFetchPlugins(
                                  discoveryState.message,
                                ),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
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
                            padding: EdgeInsets.all(16.0),
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
            ),
          );
        },
      ),
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  label: Text('v${manifest.version}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'By ${manifest.author}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(manifest.description),
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
