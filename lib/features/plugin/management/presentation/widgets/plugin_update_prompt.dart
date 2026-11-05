import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';

abstract class PluginUpdatePrompt {
  static Future<void> runStartupCheck(
    BuildContext context,
    PluginManagerCubit cubit,
  ) async {
    await cubit.refresh(fetchCatalog: true);
    if (!context.mounted) return;

    final types = cubit.state.updatableTypes;
    if (types.isEmpty) return;

    final l10n = context.l10n;
    final confirmed = await Dialogs.confirm(
      context,
      title: l10n.pluginUpdatesAvailableTitle,
      message: types
          .map((type) => _line(context, cubit.state.slot(type), type))
          .join('\n'),
      confirmLabel: l10n.pluginUpdateNow,
      cancelLabel: l10n.updateNotNow,
    );
    if (!confirmed || !context.mounted) return;

    await _updateAll(context, cubit, types);
  }

  static String _line(
    BuildContext context,
    PluginSlotState slot,
    PluginType type,
  ) => context.l10n.pluginUpdateLine(
    type.toLocalizedString(context),
    slot.installed!.version,
    slot.remote!.version,
  );

  static Future<void> _updateAll(
    BuildContext context,
    PluginManagerCubit cubit,
    List<PluginType> types,
  ) async {
    final l10n = context.l10n;
    Dialogs.showLoading(context, message: l10n.pluginUpdating);
    var updated = 0;
    for (final type in types) {
      await cubit.update(type);
      if (cubit.state.slot(type).error == null) updated++;
    }
    if (!context.mounted) return;

    Dialogs.hide(context);
    Dialogs.showMessageSnackBar(
      context,
      message: updated == types.length
          ? l10n.pluginUpdatesDone
          : l10n.pluginUpdatesPartial(updated, types.length),
    );
  }
}
