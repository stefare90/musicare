import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/presentation/utils/exception_localizer.dart';

class ErrorTile extends StatelessWidget {
  final String title;
  final Object error;
  final VoidCallback? onRetry;

  const ErrorTile({
    super.key,
    required this.title,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final localizedErrorMessage = error.toLocalizedString(context);
    final titleColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final subTextColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.35,
    );
    final iconColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.35,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.08,
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.08),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  localizedErrorMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.article_outlined, size: 16, color: iconColor),
            tooltip: l10n.viewLog,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                Dialogs.showError(context, title: title, error: error),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 2),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 16, color: iconColor),
              tooltip: l10n.refresh,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
