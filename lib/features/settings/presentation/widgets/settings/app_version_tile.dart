import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';

class AppVersionTile extends StatelessWidget {
  const AppVersionTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      builder: (context, state) {
        final extra = _extraLine(context, state);
        return ListTile(
          title: Text(l10n.settingsAppVersionTile),
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.installedLabel),
              if (extra != null)
                Text(
                  extra.$1,
                  style: context.textTheme.bodySmall?.copyWith(color: extra.$2),
                ),
            ],
          ),
          isThreeLine: extra != null,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => AppNavigator.toAppUpdate(context),
        );
      },
    );
  }

  (String, Color)? _extraLine(BuildContext context, AppUpdateState state) {
    final l10n = context.l10n;
    final text = switch (state.status) {
      AppUpdateStatus.available => l10n.updateTileSubtitleAvailable(
        state.update!.versionName,
      ),
      AppUpdateStatus.downloading => l10n.updateStatusDownloading(
        state.progressPercent,
      ),
      AppUpdateStatus.installing => l10n.updateStatusInstalling,
      _ => null,
    };
    if (text == null) return null;
    return (text, context.colorScheme.primary);
  }
}
