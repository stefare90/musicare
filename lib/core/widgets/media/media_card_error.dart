import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';

class MediaCardError extends StatelessWidget {
  final String title;
  final Object error;
  final VoidCallback? onRetry;
  final double width;

  const MediaCardError({
    super.key,
    required this.title,
    required this.error,
    this.onRetry,
    this.width = 135.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localizedErrorMessage = error.toLocalizedString(context);

    final titleColor = context.colorScheme.onSurface.withValues(alpha: 0.6);
    final subTextColor = context.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.35,
    );
    final iconColor = context.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.35,
    );

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.08,
        ),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.08),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 24, color: iconColor),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            localizedErrorMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 10.0,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.article_outlined, size: 16, color: iconColor),
                tooltip: l10n.viewLog,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    Dialogs.showError(context, title: title, error: error),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 16, color: iconColor),
                  tooltip: l10n.refresh,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
