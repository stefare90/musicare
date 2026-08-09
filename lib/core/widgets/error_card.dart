import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/features/plugin/presentation/utils/exception_localizer.dart';

class ErrorCard extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final IconData icon;
  final EdgeInsetsGeometry? margin;

  const ErrorCard({
    super.key,
    required this.error,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.margin = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fullErrorDetails = error.toString();

    return InfoCard(
      icon: icon,
      iconColor: Theme.of(context).colorScheme.error,
      title: error.toLocalizedString(context),
      onAction: onRetry,
      actionLabel: context.l10n.retry,
      onSecondaryAction: () {
        Clipboard.setData(ClipboardData(text: fullErrorDetails));
        Dialogs.showSnackBar(context, message: l10n.errorCopiedToClipboard);
      },
      secondaryActionLabel: l10n.copyError,
      secondaryActionIcon: Icons.copy_rounded,
      margin: margin,
    );
  }
}
