import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_bottom_action_button.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_step_scaffold.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class WelcomeMetadataPage extends StatelessWidget {
  final VoidCallback onContinueTap;

  const WelcomeMetadataPage({super.key, required this.onContinueTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetadataPluginCubit, MetadataPluginState>(
      builder: (context, state) {
        final activeId = state is MetadataPluginLoadedState
            ? state.manifest.id
            : null;

        return OnboardingStepScaffold(
          key: const PageStorageKey('metadata_step_page'),
          title: context.l10n.onboardingStepMetadata,
          subtitle: context.l10n.selectProviderSubtitle,
          icon: Icons.library_music_rounded,
          bottomAction: state is MetadataPluginLoadedState
              ? OnboardingBottomActionButton(
                  label: context.l10n.continueToAudioSource,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onContinueTap,
                )
              : null,
          child: PluginDiscoveryWidget(
            key: const ValueKey('metadata_discovery'),
            pluginType: PluginType.metadata,
            activePluginId: activeId,
            onInstallTap: (manifest) {
              context.read<MetadataPluginCubit>().installDiscoveredPlugin(
                manifest,
              );
            },
          ),
        );
      },
    );
  }
}
