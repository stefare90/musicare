import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_matrix_column.dart';

class SkeletonTrackMatrix extends StatelessWidget {
  final bool showTitle;
  final int rowsCount;
  final int columnCount;
  final double totalHeight;
  final double columnWidth;

  const SkeletonTrackMatrix({
    super.key,
    this.showTitle = true,
    this.columnCount = 2,
    required this.rowsCount,
    required this.totalHeight,
    required this.columnWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ShimmerBox(width: 160, height: 22),
          ),
        SizedBox(
          height: totalHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: columnCount,
            itemBuilder: (context, index) {
              return SkeletonTrackMatrixColumn(
                rowsCount: rowsCount,
                totalHeight: totalHeight,
                columnWidth: columnWidth,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
