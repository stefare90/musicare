import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/error_tile.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_error.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_section_row.dart';

class SectionRow extends StatelessWidget {
  final String title;
  final String? description;
  final List<Object> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final Object? loadMoreError;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final void Function(Object item)? onItemTap;

  const SectionRow({
    super.key,
    required this.title,
    this.description,
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.loadMoreError,
    this.onRetry,
    this.onLoadMore,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null && items.isEmpty) {
      return ErrorTile(title: title, error: error!, onRetry: onRetry ?? () {});
    }
    if (isLoading && items.isEmpty) {
      return const SkeletonSectionRow(showTitle: true);
    }
    if (items.isEmpty) return const SizedBox.shrink();

    final showTrailingCard = hasMore || isLoadingMore || loadMoreError != null;
    final rowHeight = MediaCardMetrics.rowHeight(context);
    final itemCount = items.length + (showTrailingCard ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MediaCardMetrics.edgeInset,
            vertical: MediaCardMetrics.sectionTitleVerticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textTheme.titleLarge),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(description!, style: context.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        SizedBox(
          height: rowHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (hasMore &&
                  !isLoadingMore &&
                  loadMoreError == null &&
                  scrollInfo.metrics.extentAfter < 200) {
                onLoadMore?.call();
              }
              return false;
            },
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: MediaCardMetrics.edgeInset,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final isLast = index == itemCount - 1;
                Widget child;

                if (index < items.length) {
                  final item = items[index];
                  child = MediaCard(
                    width: MediaCardMetrics.rowCardWidth,
                    item: item,
                    onTap: onItemTap != null ? () => onItemTap!(item) : null,
                  );
                } else if (loadMoreError != null) {
                  child = MediaCardError(
                    width: MediaCardMetrics.rowCardWidth,
                    title: title,
                    error: loadMoreError!,
                    onRetry: onLoadMore,
                  );
                } else {
                  if (hasMore && !isLoadingMore) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onLoadMore?.call();
                    });
                  }
                  child = ShimmerBox(
                    width: MediaCardMetrics.rowCardWidth,
                    height: rowHeight,
                    borderRadius: BorderRadius.circular(
                      MediaCardMetrics.radius,
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.only(
                    right: isLast ? 0 : MediaCardMetrics.gap,
                  ),
                  child: child,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
