import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';
import 'package:music_are/features/settings/presentation/widgets/plugin_account_section.dart';
import 'package:music_are/features/plugin/management/presentation/widgets/plugin_actions_section.dart';
import 'package:music_are/features/settings/presentation/widgets/plugin_detail_body.dart';

class PluginDetailPage extends StatelessWidget {
  final PluginType type;

  const PluginDetailPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type.toLocalizedString(context))),
      body: BlocBuilder<PluginManagerCubit, PluginManagerState>(
        builder: (context, state) {
          final manifest =
              state.slot(type).installed ??
              context.watch<PluginSessionCubit>().manifestOf(type);
          if (manifest == null) {
            return const _NotConfiguredBody();
          }

          return PluginDetailBody(
            manifest: manifest,
            sections: [
              PluginAccountSection(type: type),
              PluginActionsSection(type: type),
            ],
          );
        },
      ),
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
