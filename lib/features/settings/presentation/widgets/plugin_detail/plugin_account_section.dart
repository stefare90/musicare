import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/shared/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/settings/presentation/widgets/plugin_detail/plugin_account_tile.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';

class PluginAccountSection extends StatelessWidget {
  final PluginType type;

  const PluginAccountSection({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PluginSessionCubit, PluginSessionState>(
      builder: (context, pluginState) {
        final plugins = context.read<PluginSessionCubit>();
        if (!plugins.hasAuth(type) ||
            pluginState.stateOf(type).status != PluginLifecycleStatus.loaded) {
          return const SizedBox.shrink();
        }

        final auth = pluginState.authOf(type);
        if (auth.status == PluginAuthStatus.unavailable) {
          return const SizedBox.shrink();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSectionHeader(label: l10n.pluginAccountSection),
            PluginAccountTile(type: type, auth: auth),
          ],
        );
      },
    );
  }
}
