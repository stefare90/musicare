import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class InfoCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? message;

  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? actionIcon;

  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;

  final EdgeInsetsGeometry? margin;

  const InfoCard({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.message,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.margin = const EdgeInsets.all(16.0),
  });

  Widget? _buildButton({
    required VoidCallback? onPressed,
    String? label,
    IconData? icon,
    required Widget Function(Widget child) createButton,
    required Widget Function(Widget icon, Widget label) createIconButton,
  }) {
    if (onPressed == null) return null;

    final hasLabel = label != null && label.isNotEmpty;
    final hasIcon = icon != null;

    if (hasLabel && hasIcon) {
      return createIconButton(Icon(icon, size: 18), Text(label));
    }
    if (hasLabel) {
      return createButton(Text(label));
    }
    if (hasIcon) {
      return createButton(Icon(icon, size: 18));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    final primaryBtn = _buildButton(
      onPressed: onAction,
      label: actionLabel,
      icon: actionIcon,
      createButton: (child) =>
          ElevatedButton(onPressed: onAction, child: child),
      createIconButton: (icon, label) =>
          ElevatedButton.icon(onPressed: onAction, icon: icon, label: label),
    );

    final secondaryBtn = _buildButton(
      onPressed: onSecondaryAction,
      label: secondaryActionLabel,
      icon: secondaryActionIcon,
      createButton: (child) =>
          OutlinedButton(onPressed: onSecondaryAction, child: child),
      createIconButton: (icon, label) => OutlinedButton.icon(
        onPressed: onSecondaryAction,
        icon: icon,
        label: label,
      ),
    );

    return Card(
      elevation: 0,
      color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 36, color: effectiveIconColor),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.65,
                  ),
                ),
              ),
            ],
            if (primaryBtn != null || secondaryBtn != null) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [?primaryBtn, ?secondaryBtn],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
