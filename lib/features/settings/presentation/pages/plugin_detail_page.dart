import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';
import 'package:music_are/features/settings/presentation/widgets/metadata_account_section.dart';
import 'package:music_are/features/settings/presentation/widgets/plugin_detail_body.dart';

/// Detail of one active plugin: version, and — only when the plugin exposes an
/// account — its authentication state and the sign in/out actions.
class PluginDetailPage extends StatelessWidget {
  final PluginType type;

  const PluginDetailPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type.toLocalizedString(context))),
      body: switch (type) {
        PluginType.metadata => const _MetadataPluginDetail(),
        PluginType.audioSource => const _AudioSourcePluginDetail(),
      },
    );
  }
}

class _MetadataPluginDetail extends StatelessWidget {
  const _MetadataPluginDetail();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetadataPluginCubit, MetadataPluginState>(
      builder: (context, state) {
        if (state is! MetadataPluginLoadedState) {
          return const _NotConfiguredBody();
        }

        return PluginDetailBody(
          manifest: state.manifest,
          sections: const [MetadataAccountSection()],
        );
      },
    );
  }
}

class _AudioSourcePluginDetail extends StatelessWidget {
  const _AudioSourcePluginDetail();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioSourcePluginCubit, AudioSourcePluginState>(
      builder: (context, state) {
        if (state is! AudioSourcePluginLoadedState) {
          return const _NotConfiguredBody();
        }

        return PluginDetailBody(manifest: state.manifest);
      },
    );
  }
}

class _NotConfiguredBody extends StatelessWidget {
  const _NotConfiguredBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InfoCard(
        title: context.l10n.settingsNotConfigured,
        icon: Icons.extension_off_outlined,
      ),
    );
  }
}
