import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

/// Scrollable grid of [MediaCard]s with lazy pagination.
///
/// Source-agnostic on purpose: it does not know about cubits. The caller owns
/// the data and the pagination state and reacts to [onLoadMore], so the search
/// results, the user library and the downloads page share one implementation.
class PaginatedMediaGrid extends StatelessWidget {
  final List<Object> items;

  /// Cell-sized widgets pinned before the data items (e.g. the *Liked Songs*
  /// collection card), so a special entry shares the grid instead of breaking
  /// the layout with a differently-shaped row.
  final List<Widget> leading;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final void Function(Object item)? onItemTap;
  final EdgeInsetsGeometry padding;

  const PaginatedMediaGrid({
    super.key,
    required this.items,
    this.leading = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onItemTap,
    this.padding = const EdgeInsets.all(MediaCardMetrics.edgeInset),
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (hasMore && !isLoadingMore && scrollInfo.metrics.extentAfter < 200) {
          onLoadMore?.call();
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textBlockHeight = MediaCardMetrics.textBlockHeight(context);
          final delegate = MediaCardMetrics.gridDelegate(
            maxWidth: constraints.maxWidth,
            textBlockHeight: textBlockHeight,
          );
          final columns = delegate.crossAxisCount;
          final cellWidth = MediaCardMetrics.gridCellWidth(
            constraints.maxWidth,
            columns,
          );
          final cellHeight = cellWidth + textBlockHeight;
          final loadedCells = leading.length + items.length;
          final remainder = loadedCells % columns;
          final skeletonCount = isLoadingMore
              ? (remainder == 0 ? columns : columns - remainder)
              : 0;

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            gridDelegate: delegate,
            itemCount: leading.length + items.length + skeletonCount,
            itemBuilder: (context, index) {
              if (index < leading.length) {
                return leading[index];
              }
              final dataIndex = index - leading.length;
              if (dataIndex >= items.length) {
                return ShimmerBox(
                  width: cellWidth,
                  height: cellHeight,
                  borderRadius: BorderRadius.circular(MediaCardMetrics.radius),
                );
              }
              final item = items[dataIndex];
              return MediaCard(
                item: item,
                onTap: onItemTap != null ? () => onItemTap!(item) : null,
              );
            },
          );
        },
      ),
    );
  }
}
