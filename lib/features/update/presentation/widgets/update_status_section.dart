import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';
import 'package:music_are/features/update/presentation/widgets/update_status_tile.dart';

class UpdateStatusSection extends StatelessWidget {
  final AppUpdateState state;

  const UpdateStatusSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(label: l10n.updateStatusSection),
        UpdateStatusTile(state: state),
      ],
    );
  }
}
