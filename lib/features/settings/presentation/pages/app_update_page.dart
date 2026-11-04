import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/settings/presentation/widgets/app_version_header.dart';
import 'package:music_are/features/settings/presentation/widgets/app_version_section.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';
import 'package:music_are/features/update/presentation/widgets/update_actions_section.dart';
import 'package:music_are/features/update/presentation/widgets/update_status_section.dart';

class AppUpdatePage extends StatelessWidget {
  const AppUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppVersionTile)),
      body: BlocBuilder<AppUpdateCubit, AppUpdateState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 24.0),
            children: [
              const AppVersionHeader(),
              AppVersionSection(state: state),
              UpdateStatusSection(state: state),
              UpdateActionsSection(state: state),
            ],
          );
        },
      ),
    );
  }
}
