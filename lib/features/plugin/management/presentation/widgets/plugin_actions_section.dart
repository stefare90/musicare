import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/plugin_selection_bottom_sheet.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';

class PluginActionsSection extends StatefulWidget {
  final PluginType type;

  const PluginActionsSection({super.key, required this.type});

  @override
  State<PluginActionsSection> createState() => _PluginActionsSectionState();
}

class _PluginActionsSectionState extends State<PluginActionsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PluginManagerCubit>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PluginManagerCubit, PluginManagerState>(
      builder: (context, state) {
        final slot = state.slot(widget.type);
        final busy = slot.phase != PluginSlotPhase.idle;
        final installed =
            slot.installed ??
            context.watch<PluginSessionCubit>().manifestOf(widget.type);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSectionHeader(label: l10n.pluginActionsSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (slot.updateAvailable) ...[
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: busy
                            ? null
                            : () => context.read<PluginManagerCubit>().update(
                                widget.type,
                              ),
                        child: Text(l10n.pluginActionUpdate),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                  ],
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: busy || installed == null
                          ? null
                          : () => context.read<PluginManagerCubit>().reinstall(
                              widget.type,
                            ),
                      child: Text(l10n.pluginActionReinstall),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: busy ? null : _showAlternatives,
                      child: Text(l10n.pluginActionReplace),
                    ),
                  ),
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAlternatives() async {
    final cubit = context.read<PluginManagerCubit>();
    final manifest = await PluginSelectionBottomSheet.show(
      context,
      type: widget.type,
      alternatives: cubit.alternatives(widget.type),
    );
    if (manifest == null || !mounted) return;

    final confirmed = await Dialogs.confirm(
      context,
      title: context.l10n.pluginReplaceTitle,
      message: context.l10n.pluginReplaceMessage(manifest.name),
      confirmLabel: context.l10n.pluginActionReplace,
    );
    if (confirmed) {
      await cubit.change(widget.type, manifest);
    }
  }
}
