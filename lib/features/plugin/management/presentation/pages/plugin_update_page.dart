import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';

class PluginUpdatePage extends StatelessWidget {
  final PluginType type;

  const PluginUpdatePage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionRequiredTitle), centerTitle: true),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<PluginManagerCubit, PluginManagerState>(
              listenWhen: (previous, next) =>
                  previous.slot(type).phase != next.slot(type).phase,
              listener: (context, state) {
                if (state.slot(type).phase == PluginSlotPhase.busy) {
                  Dialogs.showLoading(context, message: l10n.installingPlugin);
                } else {
                  Dialogs.hide(context);
                }
              },
            ),
            BlocListener<PluginSessionCubit, PluginSessionState>(
              listenWhen: (previous, next) =>
                  previous.stateOf(type).status != next.stateOf(type).status,
              listener: (context, state) {
                if (state.stateOf(type).status ==
                    PluginLifecycleStatus.loaded) {
                  context.go(AppRoutes.home);
                }
              },
            ),
          ],
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: BlocBuilder<PluginManagerCubit, PluginManagerState>(
              builder: (context, managementState) {
                final runtimeManifest = context
                    .watch<PluginSessionCubit>()
                    .stateOf(type)
                    .manifest;
                final installed =
                    managementState.slot(type).installed ?? runtimeManifest;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IncompatiblePluginCard(manifest: installed),
                    PluginDiscoveryWidget(
                      pluginType: type,
                      installed: installed,
                      onSelected: (manifest) => context
                          .read<PluginManagerCubit>()
                          .change(type, manifest),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _IncompatiblePluginCard extends StatelessWidget {
  final PluginManifest? manifest;

  const _IncompatiblePluginCard({this.manifest});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final obsolete = manifest;

    return Container(
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.only(bottom: 25.0),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer.withValues(alpha: 0.2),
        border: Border.all(color: context.colorScheme.errorContainer),
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
          if (obsolete != null) ...[
            const SizedBox(height: 4),
            Text(
              obsolete.name,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.installedVersion(obsolete.version),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
}
