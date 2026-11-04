import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';

abstract class AppUpdatePrompt {
  static Future<void> runStartupCheck(AppUpdateCubit cubit) async {
    await cubit.check(silent: true);

    final state = cubit.state;
    final update = state.update;
    if (state.status != AppUpdateStatus.available || update == null) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final l10n = context.l10n;

    final confirmed = await Dialogs.confirm(
      context,
      title: l10n.updateAvailableTitle,
      message: l10n.updateDialogMessage(
        update.versionName,
        update.sizeLabel,
        state.installed?.versionName ?? '—',
      ),
      confirmLabel: l10n.updateAction,
      cancelLabel: l10n.updateNotNow,
    );
    if (!confirmed || !context.mounted) return;

    cubit.updateNow();
    Dialogs.showMessageSnackBar(context, message: l10n.updateDownloadingNotice);
  }
}
