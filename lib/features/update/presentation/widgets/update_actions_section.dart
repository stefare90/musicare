import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';

class UpdateActionsSection extends StatelessWidget {
  final AppUpdateState state;

  const UpdateActionsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AppUpdateCubit>();
    final busy =
        state.status == AppUpdateStatus.checking ||
        state.status == AppUpdateStatus.downloading ||
        state.status == AppUpdateStatus.installing;
    final canDownload =
        state.status == AppUpdateStatus.available ||
        (state.status == AppUpdateStatus.failed && state.update != null);
    final updating =
        canDownload ||
        state.status == AppUpdateStatus.downloading ||
        state.status == AppUpdateStatus.installing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(label: l10n.updateActionsSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () {
                        if (canDownload) {
                          cubit.updateNow();
                        } else {
                          cubit.check();
                        }
                      },
                icon: Icon(
                  updating ? Icons.download_rounded : Icons.refresh_rounded,
                ),
                label: Text(
                  updating ? l10n.updateAction : l10n.updateCheckForUpdate,
                ),
              ),
              if (state.status == AppUpdateStatus.checking) ...[
                const SizedBox(height: 12.0),
                const LinearProgressIndicator(),
              ],
              if (state.status == AppUpdateStatus.downloading) ...[
                const SizedBox(height: 12.0),
                LinearProgressIndicator(value: state.progress),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.transferredLabel,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: cubit.cancelDownload,
                      child: Text(l10n.updateCancel),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
