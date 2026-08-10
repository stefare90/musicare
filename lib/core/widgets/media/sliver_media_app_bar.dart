import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class SliverMediaAppBar extends StatelessWidget {
  static final ValueNotifier<bool> _defaultScrolledPast = ValueNotifier<bool>(
    true,
  );

  final String title;
  final bool isSaved;
  final ValueNotifier<bool>? isScrolledPast;
  final VoidCallback? onSaveTap;
  final VoidCallback? onOptionsTap;

  const SliverMediaAppBar({
    super.key,
    required this.title,
    this.isSaved = false,
    this.isScrolledPast,
    this.onSaveTap,
    this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => AppNavigator.pop(context),
      ),
      title: ValueListenableBuilder<bool>(
        valueListenable: isScrolledPast ?? _defaultScrolledPast,
        builder: (context, isPast, child) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isPast ? 1.0 : 0.0,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      actions: [
        if (onSaveTap != null)
          IconButton(
            icon: Icon(
              isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isSaved ? context.colorScheme.primary : null,
            ),
            onPressed: onSaveTap,
            tooltip: context.l10n.tooltipFavorite,
          ),
        if (onOptionsTap != null)
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: onOptionsTap,
            tooltip: context.l10n.tooltipMoreOptions,
          ),
      ],
    );
  }
}
