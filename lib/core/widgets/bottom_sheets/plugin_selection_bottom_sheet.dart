import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/base_modal_bottom_sheet.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';

class PluginSelectionBottomSheet {
  static Future<PluginManifest?> show(
    BuildContext context, {
    required PluginType type,
    required Future<List<PluginManifest>> alternatives,
  }) {
    return BaseModalBottomSheet.show<PluginManifest>(
      context: context,
      child: BaseModalBottomSheet(
        title: context.l10n.pluginActionReplace,
        subtitle: type.toLocalizedString(context),
        icon: Icons.swap_horiz_rounded,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return FutureBuilder<List<PluginManifest>>(
            future: alternatives,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(snapshot.error!.toLocalizedString(context)),
                );
              }
              final plugins = snapshot.data ?? const [];
              if (plugins.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(context.l10n.pluginNoAlternatives),
                );
              }
              return ListView(
                controller: scrollController,
                children: plugins
                    .map(
                      (plugin) => ListTile(
                        title: Text(plugin.name),
                        subtitle: Text('v${plugin.version} · ${plugin.author}'),
                        onTap: () => Navigator.of(context).pop(plugin),
                      ),
                    )
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }
}
