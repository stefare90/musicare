import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/error_tile.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_error.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          height: 212,
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
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              itemCount: items.length + (showTrailingCard ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < items.length) {
                  final item = items[index];
                  return MediaCard(
                    item: item,
                    onTap: onItemTap != null ? () => onItemTap!(item) : null,
                  );
                }
                if (loadMoreError != null) {
                  return MediaCardError(
                    title: title,
                    error: loadMoreError!,
                    onRetry: onLoadMore,
                  );
                }
                if (hasMore && !isLoadingMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onLoadMore?.call();
                  });
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: ShimmerBox(
                    width: 135.0,
                    height: 204.0,
                    borderRadius: BorderRadius.all(Radius.circular(14.0)),
                  ),
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
