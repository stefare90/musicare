import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class InfoCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? message;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData actionIcon;
  final EdgeInsetsGeometry? margin;

  const InfoCard({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.message,
    this.onAction,
    this.actionLabel,
    this.actionIcon = Icons.refresh,
    this.margin = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: effectiveIconColor),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium,
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
