import 'package:flutter/material.dart';
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
    return InfoCard(
      icon: icon,
      iconColor: Theme.of(context).colorScheme.error,
      title: error.toLocalizedString(context),
      onAction: onRetry,
      actionLabel: 'Retry',
      margin: margin,
    );
  }
}
