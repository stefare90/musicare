import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/management/presentation/widgets/plugin_status_card.dart';
import 'package:music_are/features/plugin/shared/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';

class PluginSetupSlot extends StatelessWidget {
  final PluginType type;
  final int index;
  final int total;

  const PluginSetupSlot({
    super.key,
    required this.type,
    this.index = 1,
    this.total = 1,
  });

  @override
  Widget build(BuildContext context) {
    final runtime = context.watch<PluginSessionCubit>().stateOf(type);
    final installed =
        context.select<PluginManagerCubit, PluginSlotState>(
          (cubit) => cubit.state.slot(type),
        ).installed ??
        runtime.manifest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (total > 1) ...[_divider(context), const SizedBox(height: 28.0)],
        PluginStatusCard(
          status: runtime.status,
          type: type,
          manifest: installed,
        ),
        PluginDiscoveryWidget(
          pluginType: type,
          installed: installed,
          header: context.l10n.pluginSetupDiscoveryHeader(
            type.toLocalizedString(context),
          ),
          onSelected: (manifest) =>
              context.read<PluginManagerCubit>().change(type, manifest),
        ),
        if (index < total) const SizedBox(height: 28.0),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            '$index / $total',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
