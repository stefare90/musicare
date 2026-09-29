import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

/// Skeleton grid matching `PaginatedMediaGrid` in the search page.
///
/// It reuses [MediaCardMetrics.gridDelegate] so each placeholder occupies
/// exactly the same cell as a real `MediaCard` (same column count, gap and
/// `TextScaler`-aware height), avoiding any visual jump when data loads.
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
        final cellWidth = MediaCardMetrics.gridCellWidth(
          constraints.maxWidth,
          delegate.crossAxisCount,
        );
        final cellHeight = cellWidth + textBlockHeight;

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: delegate,
          itemCount: itemCount,
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
