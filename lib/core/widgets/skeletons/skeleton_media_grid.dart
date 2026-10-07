import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

/// Skeleton matching `PaginatedMediaGrid` cell-for-cell, so loading never
/// causes a visual jump.
class SkeletonMediaGrid extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const SkeletonMediaGrid({
    super.key,
    this.itemCount = 8,
    this.padding = const EdgeInsets.all(MediaCardMetrics.edgeInset),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
        // Whole rows only: a partial last row would look unfinished.
        final count = MediaCardMetrics.pageSizeForColumns(itemCount, columns);

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: delegate,
          itemCount: count,
          itemBuilder: (context, index) {
            return ShimmerBox(
              width: cellWidth,
              height: cellHeight,
              borderRadius: BorderRadius.circular(MediaCardMetrics.radius),
            );
          },
        );
      },
    );
  }
}
