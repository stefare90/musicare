import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/errors/exception_localizer.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';

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
        ListTile(dense: true, title: Text(_text(context))),
      ],
    );
  }

  String _text(BuildContext context) {
    final l10n = context.l10n;
    return switch (state.status) {
      AppUpdateStatus.idle => l10n.updateStatusIdle,
      AppUpdateStatus.checking => l10n.updateStatusChecking,
      AppUpdateStatus.upToDate => l10n.updateStatusUpToDate,
      AppUpdateStatus.available => l10n.updateStatusAvailable(
        state.update!.versionName,
        state.update!.sizeLabel,
      ),
      AppUpdateStatus.downloading => l10n.updateStatusDownloading(
        state.progressPercent,
      ),
      AppUpdateStatus.installing => l10n.updateStatusInstalling,
      AppUpdateStatus.failed => state.failure!.toLocalizedString(context),
    };
  }
}
