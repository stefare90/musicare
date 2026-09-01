import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';

class MetadataPluginUpdatePage extends StatelessWidget {
  const MetadataPluginUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionRequiredTitle), centerTitle: true),
      body: SafeArea(
        child: BlocListener<MetadataPluginCubit, MetadataPluginState>(
          listener: (context, state) {
            if (state is MetadataPluginLoadingState) {
              Dialogs.showLoading(context, message: l10n.installingPlugin);
            } else if (state is MetadataPluginLoadedState) {
              Dialogs.hide(context);
              context.go('/');
            } else if (state is MetadataPluginErrorState) {
              Dialogs.hide(context);
              Dialogs.showErrorSnackBar(
                context,
                message: state.error.toLocalizedString(context),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<MetadataPluginCubit, MetadataPluginState>(
                  builder: (context, state) {
                    if (state is MetadataPluginIncompatibleState) {
                      final manifest = state.obsoleteManifest;
                      return Container(
                        padding: const EdgeInsets.all(20.0),
                        margin: const EdgeInsets.only(bottom: 25.0),
                        decoration: BoxDecoration(
                          color: context.colorScheme.errorContainer.withValues(
                            alpha: 0.2,
                          ),
                          border: Border.all(
                            color: context.colorScheme.errorContainer,
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.system_update_alt_rounded,
                              size: 50,
                              color: context.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.obsoleteProviderLabel,
                              style: context.textTheme.labelLarge?.copyWith(
                                color: context.colorScheme.error,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              manifest.name,
                              textAlign: TextAlign.center,
                              style: context.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.installedVersion(manifest.version),
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.providerIncompatibleMessage,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const PluginDiscoveryWidget(pluginType: PluginType.metadata),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
