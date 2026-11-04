import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/errors/error_table.dart';
import 'package:music_are/core/notice/notice.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';

class UpdateErrorTable implements ErrorTable {
  const UpdateErrorTable();

  @override
  ErrorSpec? describe(Object error, AppLocalizations l10n) {
    if (error is! AppUpdateFailure) return null;
    return switch (error) {
      UpdateCheckFailed(:final statusCode) => ErrorSpec(
        statusCode == 403 || statusCode == 429
            ? l10n.updateErrorRateLimited
            : l10n.updateErrorCheck,
      ),
      UpdateDownloadFailed() => ErrorSpec(
        l10n.updateErrorDownload,
        action: _retry,
      ),
      UpdateCorrupted() => ErrorSpec(l10n.updateErrorCorrupted, action: _retry),
      UpdateRejected() => ErrorSpec(l10n.updateErrorRejected),
      UpdateInstallFailed() => ErrorSpec(l10n.updateErrorInstall),
    };
  }

  @override
  bool notifies(Object error) => false;

  static NoticeAction _retry(BuildContext context) => (
    label: context.l10n.retry,
    onAction: () => context.read<AppUpdateCubit>().updateNow(),
  );
}
