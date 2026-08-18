import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

class SkeletonTrackMatrixColumn extends StatelessWidget {
  final int rowsCount;
  final double columnWidth;
  final double totalHeight;

  const SkeletonTrackMatrixColumn({
    super.key,
    required this.rowsCount,
    required this.columnWidth,
    required this.totalHeight,
  });

  @override
  Widget build(BuildContext context) {
    final rowSlotHeight = totalHeight / rowsCount;

    return Container(
      width: columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: List.generate(
          rowsCount,
          (_) => SizedBox(
            height: rowSlotHeight,
            child: const Center(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 2.0,
                ),
                leading: ShimmerBox(
                  width: 44.0,
                  height: 44.0,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerBox(width: 140.0, height: 14.0),
                    SizedBox(height: 6.0),
                    ShimmerBox(width: 85.0, height: 11.0),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerBox(width: 32.0, height: 11.0),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.transparent),
                      onPressed: null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
