import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_bottom_action_button.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_step_scaffold.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class WelcomeAudioSourcePage extends StatelessWidget {
  final VoidCallback onFinishTap;

  const WelcomeAudioSourcePage({super.key, required this.onFinishTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioSourcePluginCubit, AudioSourcePluginState>(
      builder: (context, state) {
        final activeId = state is AudioSourcePluginLoadedState
            ? state.manifest.id
            : null;

        return OnboardingStepScaffold(
          key: const PageStorageKey('audio_source_step_page'),
          title: context.l10n.onboardingStepAudioSource,
          subtitle: context.l10n.selectAudioSourceSubtitle,
          icon: Icons.graphic_eq_rounded,
          bottomAction: state is AudioSourcePluginLoadedState
              ? OnboardingBottomActionButton(
                  label: context.l10n.finishSetup,
                  icon: Icons.check_rounded,
                  onPressed: onFinishTap,
                )
              : null,
          child: PluginDiscoveryWidget(
            key: const ValueKey('audio_source_discovery'),
            pluginType: PluginType.audioSource,
            activePluginId: activeId,
            onInstallTap: (manifest) {
              context.read<AudioSourcePluginCubit>().installDiscoveredPlugin(
                manifest,
              );
            },
          ),
        );
      },
    );
  }
}
