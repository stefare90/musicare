import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

/// Skeleton matching a horizontal `SectionRow` from [MediaCardMetrics].
class SkeletonSectionRow extends StatelessWidget {
  final bool showTitle;

  const SkeletonSectionRow({super.key, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    final rowHeight = MediaCardMetrics.rowHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MediaCardMetrics.edgeInset,
              vertical: MediaCardMetrics.sectionTitleVerticalPadding,
            ),
            child: ShimmerBox(
              width: 200.0,
              height: MediaCardMetrics.sectionTitleHeight(context),
            ),
          ),
        SizedBox(
          height: rowHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: MediaCardMetrics.edgeInset,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == 3 ? 0 : MediaCardMetrics.gap,
                ),
                child: ShimmerBox(
                  width: MediaCardMetrics.rowCardWidth,
                  height: rowHeight,
                  borderRadius: BorderRadius.circular(MediaCardMetrics.radius),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
