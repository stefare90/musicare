import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);

    return InfoCard(
      icon: icon,
      iconColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      title: error.toLocalizedString(context),
      onAction: onRetry,
      actionLabel: l10n.retry,
      actionIcon: Icons.refresh_rounded,
      onSecondaryAction: () =>
          Dialogs.showError(context, title: l10n.error, error: error),
      secondaryActionLabel: l10n.viewLog,
      secondaryActionIcon: Icons.article_outlined,
      margin: margin,
    );
  }
}
